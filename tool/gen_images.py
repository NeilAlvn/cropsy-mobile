#!/usr/bin/env python3
"""Generate Cropsy's illustration assets on the 69labs image API.

The API is three calls: POST /api/v1/images/generate returns a job id, GET
/api/v1/jobs polls it, and GET /api/v1/images/download/<id> redirects to the
file. Request body: prompt, model, aspectRatio, resolution, count, imageUrls
(reference images, for keeping one character consistent across poses).

Usage:
    LABS69_API_KEY=... python3 tool/gen_images.py <spec.json> <out-dir>

The spec is {"name": "prompt", ...}; every entry becomes <out-dir>/<name>.jpg.
Entries whose file already exists are skipped, so a re-run costs nothing.
"""

import json
import os
import sys
import time
import urllib.request

BASE = "https://69labs.vip/api/v1"
MODEL = "nano-banana-2"
KEY = os.environ["LABS69_API_KEY"]


def call(path, body=None, redirect=True):
    req = urllib.request.Request(
        BASE + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"},
        method="POST" if body is not None else "GET",
    )
    opener = urllib.request.build_opener()
    if not redirect:
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, *a, **kw):
                return None
        opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(req, timeout=120) as r:
            return r.status, r.read(), r.headers
    except urllib.error.HTTPError as e:
        return e.code, e.read(), e.headers


def generate(prompt, aspect="1:1", refs=None):
    body = {"prompt": prompt, "model": MODEL, "aspectRatio": aspect, "resolution": "1k"}
    if refs:
        body["imageUrls"] = refs
    while True:
        status, raw, _ = call("/images/generate", body)
        if status in (200, 201):
            return json.loads(raw)["id"]
        # The account has a concurrency cap; the error says how long to hold off.
        if status == 429:
            wait_s = json.loads(raw).get("details", {}).get("retryAfterSeconds", 5)
            time.sleep(wait_s + 1)
            continue
        raise RuntimeError(f"generate failed ({status}): {raw[:300]!r}")


def download(job_id, path, timeout=600):
    """Poll the download route until the job produces a file.

    The jobs feed only lists the last few minutes, so a finished job can drop
    out of it before we look; the download route is the durable signal.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        # The route 302s to the CDN; the opener follows it and returns bytes.
        status, raw, _ = call(f"/images/download/{job_id}")
        if status == 200:
            with open(path, "wb") as f:
                f.write(raw)
            return
        # "no downloadable output" is what a still-running job answers.
        if status not in (400, 404, 409, 425):
            raise RuntimeError(f"download failed ({status}): {raw[:200]!r}")
        _, feed, _ = call("/jobs?kind=images&limit=50")
        for job in json.loads(feed)["jobs"]:
            if job["id"] == job_id and job["status"] in ("FAILED", "CANCELLED"):
                raise RuntimeError(f"{job_id}: {job['status']} {job.get('userMessage')}")
        time.sleep(5)
    raise TimeoutError(job_id)


def main():
    spec_path, out_dir = sys.argv[1], sys.argv[2]
    spec = json.load(open(spec_path))
    aspect = spec.pop("_aspect", "1:1")
    refs = spec.pop("_refs", None)
    os.makedirs(out_dir, exist_ok=True)

    pending = {}
    for name, prompt in spec.items():
        path = os.path.join(out_dir, f"{name}.jpg")
        if os.path.exists(path):
            print(f"skip {name}")
            continue
        pending[name] = (generate(prompt, aspect, refs), path)
        print(f"queued {name}")
        time.sleep(1)

    for name, (job_id, path) in pending.items():
        download(job_id, path)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
