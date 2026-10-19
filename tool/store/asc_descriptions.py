#!/usr/bin/env python3
"""Pushes `## description` from tool/store/metadata/*.md to the editable iOS
version on App Store Connect. Dry run by default; `--apply` writes.

Run from cropsy-mobile: python3 tool/store/asc_descriptions.py [--apply]
"""
import base64, json, re, sys, time, urllib.request
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

KEY_ID, ISSUER, APP = 'HYH97DCL82', '47f95e96-b09e-48b1-85e1-37886c9c2177', '6811652686'
KEY = Path.home() / f'.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8'
# metadata file -> ASC locale
LOCALES = {'en-GB': 'en-GB', 'en-US': 'en-US', 'nl': 'nl-NL', 'de': 'de-DE', 'fr': 'fr-FR', 'sv': 'sv', 'pt': 'pt-PT'}
EDITABLE = {'PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY'}


def b64(b): return base64.urlsafe_b64encode(b).rstrip(b'=').decode()


def token():
    head = b64(json.dumps({'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'}).encode())
    body = b64(json.dumps({'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 600,
                           'aud': 'appstoreconnect-v1'}).encode())
    key = serialization.load_pem_private_key(KEY.read_bytes(), None)
    r, s = decode_dss_signature(key.sign(f'{head}.{body}'.encode(), ec.ECDSA(hashes.SHA256())))
    return f'{head}.{body}.{b64(r.to_bytes(32, "big") + s.to_bytes(32, "big"))}'


def call(method, path, data=None):
    req = urllib.request.Request('https://api.appstoreconnect.apple.com' + path, method=method,
                                 data=json.dumps(data).encode() if data else None,
                                 headers={'Authorization': f'Bearer {token()}', 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as res:
        return json.load(res)


def description(f):
    return re.search(r'^## description\n([\s\S]*?)(?=^## |\Z)', f.read_text(), re.M).group(1).strip()


apply = '--apply' in sys.argv
versions = call('GET', f'/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=10')['data']
version = next(v for v in versions if v['attributes']['appStoreState'] in EDITABLE)
print(f"version {version['attributes']['versionString']} ({version['attributes']['appStoreState']})")
locs = {l['attributes']['locale']: l for l in
        call('GET', f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")['data']}

for stem, locale in LOCALES.items():
    want = description(Path(f'tool/store/metadata/{stem}.md'))
    loc = locs.get(locale)
    if not loc: print(f'{locale}: missing on ASC'); continue
    if (loc['attributes'].get('description') or '').strip() == want: print(f'{locale}: up to date'); continue
    print(f'{locale}: differs, new tail: ...{want[-160:]!r}')
    if apply:
        call('PATCH', f"/v1/appStoreVersionLocalizations/{loc['id']}",
             {'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id'], 'attributes': {'description': want}}})
        print(f'{locale}: updated')
if not apply: print('dry run; rerun with --apply to write')
