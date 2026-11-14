#!/usr/bin/env python3
"""Pushes the store listing from tool/store/metadata/*.md and the framed screenshots
in tool/store/upload/<locale>/ to the editable iOS version on App Store Connect.
Dry run by default; `--apply` writes.

  python3 tool/store/asc_listing.py [--create 1.2] [--shots en-US,en-GB,en-AU] [--apply]

- `--create X`: create iOS version X when no version is editable.
- Text: name + subtitle (app info), description, keywords, What's New (version).
  A missing localisation (e.g. en-AU) is created.
- `--shots`: for each listed locale, replace the 6.9" (APP_IPHONE_67) set with
  upload/<locale>/1.png … 6.png, uploaded one at a time in that order.
Run from cropsy-mobile. Uses the ASC API key (HYH97DCL82).
"""
import hashlib, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from asc_descriptions import APP, EDITABLE, LOCALES, call  # noqa: E402  (shared auth/call)

apply = '--apply' in sys.argv
arg = lambda flag: sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else None
SHOT_TYPE = 'APP_IPHONE_67'  # the 6.9" set (1320x2868)


def section(text, name):
    m = re.search(rf'^## {name}\n([\s\S]*?)(?=^## |\Z)', text, re.M)
    return m.group(1).strip() if m else None


def write(method, path, data=None):
    print(f'  {"" if apply else "(dry) "}{method} {path}')
    return call(method, path, data) if apply else None


# ── version ───────────────────────────────────────────────────────────────
versions = call('GET', f'/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=10')['data']
version = next((v for v in versions if v['attributes']['appStoreState'] in EDITABLE), None)
if not version:
    want = arg('--create')
    if not want: sys.exit('no editable iOS version; pass --create <version>')
    print(f'create iOS version {want}')
    r = write('POST', '/v1/appStoreVersions', {'data': {'type': 'appStoreVersions',
        'attributes': {'platform': 'IOS', 'versionString': want, 'releaseType': 'MANUAL'},
        'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})
    if not apply: sys.exit('dry run stops here (no version yet)')
    version = r['data']
print(f"version {version['attributes']['versionString']} ({version['attributes']['appStoreState']})")
vlocs = {l['attributes']['locale']: l for l in
         call('GET', f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")['data']}

info = next(i for i in call('GET', f'/v1/apps/{APP}/appInfos')['data']
            if i['attributes'].get('appStoreState') in EDITABLE | {'PREPARE_FOR_SUBMISSION'})
ilocs = {l['attributes']['locale']: l for l in
         call('GET', f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=50")['data']}

# ── text ──────────────────────────────────────────────────────────────────
for stem, locale in LOCALES.items():
    text = Path(f'tool/store/metadata/{stem}.md').read_text()
    v_attrs = {k: section(text, s) for k, s in
               [('description', 'description'), ('keywords', 'keywords'), ('whatsNew', 'whats_new')]}
    v_attrs = {k: v for k, v in v_attrs.items() if v}
    i_attrs = {'name': section(text, 'title'), 'subtitle': section(text, 'subtitle')}

    il = ilocs.get(locale)
    if not il:
        print(f'{locale}: create app info localisation')
        base = ilocs.get('en-GB', {}).get('attributes', {})
        write('POST', '/v1/appInfoLocalizations', {'data': {'type': 'appInfoLocalizations',
              'attributes': {'locale': locale, **i_attrs, 'privacyPolicyUrl': base.get('privacyPolicyUrl')},
              'relationships': {'appInfo': {'data': {'type': 'appInfos', 'id': info['id']}}}}})
    elif any((il['attributes'].get(k) or '') != v for k, v in i_attrs.items()):
        print(f"{locale}: name/subtitle {il['attributes'].get('name')!r}/{il['attributes'].get('subtitle')!r} -> {i_attrs['name']!r}/{i_attrs['subtitle']!r}")
        write('PATCH', f"/v1/appInfoLocalizations/{il['id']}",
              {'data': {'type': 'appInfoLocalizations', 'id': il['id'], 'attributes': i_attrs}})

    vl = vlocs.get(locale)
    if not vl:
        print(f'{locale}: create version localisation')
        base = vlocs.get('en-GB', {}).get('attributes', {})
        r = write('POST', '/v1/appStoreVersionLocalizations', {'data': {'type': 'appStoreVersionLocalizations',
                  'attributes': {'locale': locale, **v_attrs,
                                 **{k: base.get(k) for k in ('supportUrl', 'marketingUrl') if base.get(k)}},
                  'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version['id']}}}}})
        if r: vlocs[locale] = r['data']
    else:
        diff = {k: v for k, v in v_attrs.items() if (vl['attributes'].get(k) or '').strip() != v}
        if diff:
            print(f'{locale}: version text differs in {sorted(diff)}')
            write('PATCH', f"/v1/appStoreVersionLocalizations/{vl['id']}",
                  {'data': {'type': 'appStoreVersionLocalizations', 'id': vl['id'], 'attributes': diff}})
        else:
            print(f'{locale}: version text up to date')

# ── screenshots ───────────────────────────────────────────────────────────
for locale in filter(None, (arg('--shots') or '').split(',')):
    files = sorted(Path(f'tool/store/upload/{locale}').glob('[0-9].png'))
    print(f'{locale}: {len(files)} screenshots -> {SHOT_TYPE}')
    vl = vlocs.get(locale)
    if not vl: print('  (localisation not created yet in a dry run)'); continue
    sets = call('GET', f"/v1/appStoreVersionLocalizations/{vl['id']}/appScreenshotSets")['data']
    s = next((x for x in sets if x['attributes']['screenshotDisplayType'] == SHOT_TYPE), None)
    if s:
        for old in call('GET', f"/v1/appScreenshotSets/{s['id']}/appScreenshots?limit=50")['data']:
            write('DELETE', f"/v1/appScreenshots/{old['id']}")
    else:
        r = write('POST', '/v1/appScreenshotSets', {'data': {'type': 'appScreenshotSets',
                  'attributes': {'screenshotDisplayType': SHOT_TYPE},
                  'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': vl['id']}}}}})
        s = r and r['data']
    for f in files:  # one at a time: the set keeps upload order
        data = f.read_bytes()
        r = write('POST', '/v1/appScreenshots', {'data': {'type': 'appScreenshots',
                  'attributes': {'fileName': f.name, 'fileSize': len(data)},
                  'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': s and s['id']}}}}})
        if not apply: continue
        shot = r['data']
        import urllib.request
        for op in shot['attributes']['uploadOperations']:
            req = urllib.request.Request(op['url'], method=op['method'],
                                         data=data[op['offset']:op['offset'] + op['length']],
                                         headers={h['name']: h['value'] for h in op['requestHeaders']})
            urllib.request.urlopen(req).read()
        call('PATCH', f"/v1/appScreenshots/{shot['id']}", {'data': {'type': 'appScreenshots', 'id': shot['id'],
             'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()}}})
        print(f'  uploaded {f.name}')
