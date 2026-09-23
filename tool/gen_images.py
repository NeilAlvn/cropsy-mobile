#!/usr/bin/env python3
"""Generate Cropsy's illustration assets on the 69labs image API.

The API is three calls: POST /api/v1/images/generate returns a job id, GET
/api/v1/jobs polls it, and GET /api/v1/images/download/<id> redirects to the
file. Request body: prompt, model, aspectRatio, resolution, count, imageUrls
(reference images, for keeping one character consistent across poses).

Usage:
    LABS69_API_KEY=... python3 tool/gen_images.py <spec.json> <out-dir>

The spec is {"name": "prompt", ...}; every entry becomes <out-dir>/<name>.<ext>.
Entries whose file already exists are skipped, so a re-run costs nothing.

Keys starting with an underscore configure the run rather than naming an image:

    _aspect      "1:1" (default), "9:16", ...
    _resolution  "1k" (default), "2k", "4k"
    _ext         "jpg" (default) or "png" — png for anything with alpha
    _refs        reference image URLs, for holding a character across poses
    _ref_each    a path template like "assets/mascot/{name}.png" — each entry is
                 generated against its OWN existing file, which is how a pose is
                 upscaled in place rather than reinvented
    _ref_file    one local file used as the reference for every entry
    _cutout      true to key a flat #FF00FF background out and write a PNG with
                 real alpha (the API only ever answers JPEG, so this is how the
                 mascot gets transparency)
    _ref_from    the name of an entry in this spec to generate FIRST and then
                 use as the reference for every other entry. This is how the
                 mascot keeps one face: idle is drawn, then the other poses are
                 drawn against it.

Every run also writes <out-dir>/_urls.json, the public CDN url per image, so a
later spec can pass one back in as _refs.
"""

import base64
import json
import mimetypes
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cutout  # noqa: E402

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


def data_uri(path):
    """A local file as a reference image.

    The API takes no uploads, but `imageUrls` accepts a data URI, which is what
    lets an asset already in the repo be the reference without hosting it.
    """
    mime = mimetypes.guess_type(path)[0] or "image/png"
    with open(path, "rb") as f:
        return f"data:{mime};base64," + base64.b64encode(f.read()).decode()


def generate(prompt, aspect="1:1", refs=None, resolution="1k"):
    body = {
        "prompt": prompt,
        "model": MODEL,
        "aspectRatio": aspect,
        "resolution": resolution,
    }
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

    Returns the public CDN url, which is what a later spec passes back in as a
    reference image.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        # Ask without following the redirect first: the Location header is the
        # public url, and it is the only place the API hands it over.
        status, _, headers = call(f"/images/download/{job_id}", redirect=False)
        url = headers.get("Location") if status in (301, 302, 303, 307, 308) else None
        # The route 302s to the CDN; the opener follows it and returns bytes.
        status, raw, _ = call(f"/images/download/{job_id}")
        if status == 200:
            with open(path, "wb") as f:
                f.write(raw)
            return url
        # The poll route is rate limited too, and a burst of queued jobs is
        # exactly what trips it. Hold off for as long as it asks.
        if status == 429:
            try:
                wait_s = json.loads(raw).get("details", {}).get("retryAfterSeconds", 5)
            except ValueError:
                wait_s = 5
            time.sleep(wait_s + 1)
            continue
        # "no downloadable output" is what a still-running job answers.
        if status not in (400, 404, 409, 425):
            raise RuntimeError(f"download failed ({status}): {raw[:200]!r}")
        _, feed, _ = call("/jobs?kind=images&limit=50")
        for job in json.loads(feed)["jobs"]:
            if job["id"] == job_id and job["status"] in ("FAILED", "CANCELLED"):
                raise RuntimeError(f"{job_id}: {job['status']} {job.get('userMessage')}")
        time.sleep(5)
    raise TimeoutError(job_id)


def run(names, spec, out_dir, aspect, refs, resolution, ext, urls, cut=False,
        ref_each=None):
    """Queue every name that has no file yet, then collect them."""
    pending = {}
    for name in names:
        path = os.path.join(out_dir, f"{name}.{ext}")
        final = os.path.splitext(path)[0] + ".png" if cut else path
        if os.path.exists(final):
            print(f"skip {name}")
            continue
        # Each entry against its own existing art, when the run is an upscale.
        own = ref_each and ref_each.format(name=name)
        use = [data_uri(own)] if own and os.path.exists(own) else refs
        pending[name] = (generate(spec[name], aspect, use, resolution), path)
        print(f"queued {name}")
        time.sleep(1)

    for name, (job_id, path) in pending.items():
        url = download(job_id, path)
        if url:
            urls[name] = url
        if cut:
            png = os.path.splitext(path)[0] + ".png"
            cutout.cut(path, png)
            os.remove(path)
            path = png
        print(f"wrote {path}")


def main():
    spec_path, out_dir = sys.argv[1], sys.argv[2]
    spec = json.load(open(spec_path))
    aspect = spec.pop("_aspect", "1:1")
    refs = spec.pop("_refs", None)
    resolution = spec.pop("_resolution", "1k")
    ext = spec.pop("_ext", "jpg")
    first = spec.pop("_ref_from", None)
    ref_each = spec.pop("_ref_each", None)
    ref_file = spec.pop("_ref_file", None)
    cut = spec.pop("_cutout", False)
    if cut:
        # The API answers JPEG; the PNG is what the cutout writes.
        ext = "jpg"
    if ref_file:
        refs = [data_uri(ref_file)]
    os.makedirs(out_dir, exist_ok=True)

    urls_path = os.path.join(out_dir, "_urls.json")
    urls = json.load(open(urls_path)) if os.path.exists(urls_path) else {}

    names = list(spec)
    if first:
        # The reference has to exist before anything can be drawn against it,
        # so it runs on its own and the rest wait for its url.
        run([first], spec, out_dir, aspect, refs, resolution, ext, urls, cut,
            ref_each)
        if first not in urls:
            raise RuntimeError(
                f"{first} produced no url to reference; delete "
                f"{out_dir}/{first}.{ext} and re-run"
            )
        refs = [urls[first]]
        names = [n for n in names if n != first]

    run(names, spec, out_dir, aspect, refs, resolution, ext, urls, cut, ref_each)

    with open(urls_path, "w") as f:
        json.dump(urls, f, indent=2)


if __name__ == "__main__":
    main()
