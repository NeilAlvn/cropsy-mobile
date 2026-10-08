#!/usr/bin/env python3
"""Export/import/check the per-language fields of Str.* and MascotLines.*.

Constants only: `static const x = LocalizedText(nl: ..., en: ..., de: ...);`
Functions (`static LocalizedText x(...) =>`) are exported for reference and
skipped on import; they are translated by hand because they contain Dart.
"""
import csv, re, sys
from pathlib import Path

FILES = ['lib/l10n/strings.dart', 'lib/l10n/mascot_lines.dart']
LANGS = ['nl', 'en', 'de', 'fr', 'sv', 'pt']
# One constant or function, up to its closing `);`. Strings never contain `);`.
BLOCK = re.compile(
    r'static (?P<kind>const|LocalizedText) (?P<name>\w+)(?P<sig>\([^)]*\))?\s*=>?\s*(const )?LocalizedText\((?P<body>.*?)\);',
    re.S)
STR = r"""(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")"""
FIELD = lambda lang: re.compile(rf"\b{lang}:\s*(?P<val>(?:{STR}\s*)+)", re.S)

ESC = {'n': '\n', 't': '\t'}

def dart_to_text(val: str) -> str:
    """Dart literals -> plain text (CSV carries real newlines, not `\\n`)."""
    return ''.join(re.sub(r'\\(.)', lambda e: ESC.get(e[1], e[1]), p[1:-1], flags=re.S)
                   for p in re.findall(STR, val))

def text_to_dart(text: str) -> str:
    t = text.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    return "'" + t.replace('\r\n', '\n').replace('\n', '\\n').replace('\t', '\\t') + "'"

def blocks(src: str):
    return list(BLOCK.finditer(src))

def export(lang: str):
    w = csv.writer(sys.stdout)
    w.writerow(['file', 'name', 'en', lang])
    for f in FILES:
        for m in blocks(Path(f).read_text()):
            body = m['body']
            en, cur = FIELD('en').search(body), FIELD(lang).search(body)
            if m['kind'] == 'const':
                w.writerow([f, m['name'], dart_to_text(en['val']), dart_to_text(cur['val']) if cur else ''])
            else:
                w.writerow([f, m['name'] + m['sig'], 'FN: ' + body.strip(), 'FN: ' + (cur['val'].strip() if cur else '')])

def import_(lang: str, path: str):
    rows = {(r['file'], r['name']): r[lang] for r in csv.DictReader(open(path)) if r[lang] and not r['en'].startswith('FN: ')}
    for f in FILES:
        src = Path(f).read_text()
        out, pos = [], 0
        for m in blocks(src):
            key = (f, m['name'])
            if m['kind'] != 'const' or key not in rows:
                continue
            body = m['body']
            field = f"{lang}: {text_to_dart(rows[key])}"
            cur = FIELD(lang).search(body)
            if cur:
                new_body = body[:cur.start()] + field + body[cur.end():]
            else:
                new_body = body.rstrip().rstrip(',') + ',\n    ' + field + ',\n  '
            out.append(src[pos:m.start('body')] + new_body)
            pos = m.end('body')
        out.append(src[pos:])
        Path(f).write_text(''.join(out))

def check(lang: str) -> int:
    missing = [f"{f}:{m['name']}" for f in FILES for m in blocks(Path(f).read_text())
               if not re.search(rf'\b{lang}:', m['body'])]  # functions too: ternaries don't match FIELD
    print('\n'.join(missing) or f'ok: every string has {lang}')
    return 1 if missing else 0

if __name__ == '__main__':
    cmd, lang, *rest = sys.argv[1:]
    assert lang in LANGS, lang
    if cmd == 'export': export(lang)
    elif cmd == 'import': import_(lang, rest[0])
    elif cmd == 'check': sys.exit(check(lang))
    else: sys.exit(f'unknown command {cmd}')
