#!/usr/bin/env python3
"""Fetch one free-licensed placeholder photo per crop from Wikipedia (Wikimedia
Commons, mostly CC-BY-SA / public domain) into assets/crops/<slug>.jpg, and write
CREDITS.md with source + license. Prototype placeholders — swap for owned
photography before launch. Any crop that fails just gets no file; the CropImage
widget falls back to a coloured placeholder.
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "crops")
SNAP = os.path.join(ROOT, "assets", "data", "crops-snapshot.json")
UA = "CropsyPrototype/0.1 (contact: dev@visiontech.example) placeholder-image-fetch"

# Slugs whose Wikipedia title isn't just the sentence-cased slug.
OVERRIDES = {
    "aubergine": "Eggplant",
    "courgette": "Zucchini",
    "rocket": "Arugula",
    "pepper": "Bell pepper",
    "chili": "Chili pepper",
    "swede": "Rutabaga",
    "mangetout": "Snow pea",
    "lambs-lettuce": "Lamb's lettuce",
    "pointed-cabbage": "Cabbage",
    "gherkin": "Cucumber",
    "sweetcorn": "Sweet corn",
    "french-bean": "Green bean",
    "spring-onion": "Scallion",
    "pak-choi": "Bok choy",
    "swiss-chard": "Chard",
}


def title_for(slug: str) -> str:
    if slug in OVERRIDES:
        return OVERRIDES[slug]
    words = slug.replace("-", " ")
    return words[:1].upper() + words[1:]  # sentence case


def summary(title: str):
    url = "https://en.wikipedia.org/api/rest_v1/page/summary/" + urllib.parse.quote(title)
    req = urllib.request.Request(url, headers={"User-Agent": UA, "accept": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def pick_image(js):
    # Try a 500px thumbnail (a width Wikimedia always serves), else the
    # summary's own thumbnail as-is, else the original.
    thumb = (js.get("thumbnail") or {}).get("source")
    if thumb:
        bumped = re.sub(r"/\d+px-([^/]+)$", r"/500px-\1", thumb)
        return [bumped, thumb]
    orig = (js.get("originalimage") or {}).get("source")
    return [orig] if orig else []


def download(url: str, dest: str):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = r.read()
    with open(dest, "wb") as f:
        f.write(data)


def main():
    os.makedirs(OUT, exist_ok=True)
    slugs = sorted(c["slug"] for c in json.load(open(SNAP))["crops"])
    credits = ["# Crop photo credits (prototype placeholders)",
               "",
               "Free-licensed images from Wikipedia/Wikimedia Commons. Replace with owned",
               "photography before launch. Each line: slug — source page — image URL.", ""]
    ok, miss = 0, 0
    for slug in slugs:
        title = title_for(slug)
        try:
            js = summary(title)
            candidates = [u for u in pick_image(js) if u and not u.lower().endswith(".svg")]
            if not candidates:
                raise ValueError("no raster image")
            used = None
            for url in candidates:
                try:
                    download(url, os.path.join(OUT, slug + ".jpg"))
                    used = url
                    break
                except Exception:  # noqa: BLE001
                    continue
            if not used:
                raise ValueError("all candidate downloads failed")
            page = (js.get("content_urls", {}).get("desktop", {}) or {}).get("page", "")
            credits.append(f"- {slug} — {page} — {used}")
            ok += 1
            print(f"ok   {slug:16} <- {title}")
        except Exception as e:  # noqa: BLE001
            miss += 1
            credits.append(f"- {slug} — (no image: {e})")
            print(f"MISS {slug:16} ({e})", file=sys.stderr)
    with open(os.path.join(OUT, "CREDITS.md"), "w") as f:
        f.write("\n".join(credits) + "\n")
    print(f"\nDone: {ok} images, {miss} misses -> {OUT}")


if __name__ == "__main__":
    main()
