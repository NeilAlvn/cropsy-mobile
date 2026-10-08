#!/usr/bin/env python3
"""Checks tool/store/metadata/*.md against App Store and Play limits.

Format per file: `## title`, `## subtitle`, `## keywords`, `## short` (Play),
`## description`, `## whats_new`, each followed by its text.
"""
import re, sys
from pathlib import Path
LIMITS = {'title': 30, 'subtitle': 30, 'keywords': 100, 'short': 80, 'description': 4000, 'whats_new': 4000}
bad = 0
for f in sorted(Path('tool/store/metadata').glob('*.md')):
    sections = dict(re.findall(r'^## (\w+)\n([\s\S]*?)(?=^## |\Z)', f.read_text(), re.M))
    for k, lim in LIMITS.items():
        v = sections.get(k, '').strip()
        if not v: print(f'{f.name}: missing {k}'); bad += 1; continue
        if len(v) > lim: print(f'{f.name}: {k} is {len(v)} > {lim}'); bad += 1
    kw = sections.get('keywords', '')
    if ', ' in kw: print(f'{f.name}: keywords contain ", " (spaces waste characters)'); bad += 1
    title_words = set(re.findall(r'\w+', (sections.get('title','') + ' ' + sections.get('subtitle','')).lower()))
    dup = [w for w in kw.lower().split(',') if w in title_words]
    if dup: print(f'{f.name}: keywords repeat title/subtitle words: {dup} (Apple indexes those already)'); bad += 1
print('ok' if not bad else f'{bad} problem(s)')
sys.exit(1 if bad else 0)
