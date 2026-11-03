#!/usr/bin/env python3
"""Build brick_4's conservative linear interior weight from aligned CC0 height.

Requires Pillow, NumPy, SciPy. No source color or physical material map is edited.
Use --source PATH for an offline copy of the exact upstream displacement PNG.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import urllib.request

import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt

ROOT = Path(__file__).resolve().parents[1]
URL = "https://dl.polyhaven.org/file/ph-assets/Textures/png/1k/brick_4/brick_4_disp_1k.png"
MD5 = "4df23e378c99c42ea1901f8c3e55c9fc"
USER_AGENT = "godot-hex-detiling-source-mask/0.5 (CC0 brick_4 aligned mask preprocessing)"
HEIGHT_THRESHOLD = 96
GUARD_PIXELS = 3.0
FEATHER_PIXELS = 5.0


def build_mask(height):
    """Return repeat-safe weights; distance includes neighboring source repeats."""
    rows, cols = height.shape
    safe = height > HEIGHT_THRESHOLD
    distances = distance_transform_edt(np.tile(safe, (3, 3)))[rows:2*rows, cols:2*cols]
    t = np.clip((distances - GUARD_PIXELS) / FEATHER_PIXELS, 0.0, 1.0)
    return np.rint(255 * t * t * (3 - 2 * t)).astype(np.uint8)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path)
    args = parser.parse_args()
    if args.source:
        raw = args.source.read_bytes()
    else:
        request = urllib.request.Request(URL, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read()
    if hashlib.md5(raw).hexdigest() != MD5:
        raise ValueError("Upstream height checksum differs; inspect before regenerating")
    height_image = Image.open(io.BytesIO(raw))
    if height_image.mode != "L" or height_image.size != (1024, 1024):
        raise ValueError("Expected aligned single-channel 8-bit 1K height")
    mask = build_mask(np.asarray(height_image))
    output = ROOT / "assets/gallery/brick_4_interior_mask.png"
    Image.fromarray(mask).save(output)
    docs = ROOT / "docs/brick_guard"
    docs.mkdir(parents=True, exist_ok=True)
    albedo = Image.open(ROOT / "assets/gallery/brick_4_albedo.jpg").convert("RGB")
    a = np.asarray(albedo, dtype=float)
    protected = (1 - mask.astype(float) / 255)[..., None]
    overlay = Image.fromarray(np.rint(a * (1 - .55 * protected) + np.array([0, 180, 255]) * .55 * protected).astype(np.uint8))
    sheet = Image.new("RGB", (1056, 1120), "#171b21")
    draw = ImageDraw.Draw(sheet)
    for image, label, x, y in [
        (albedo, "Original CC0 brick_4 albedo (unaltered)", 16, 16),
        (height_image, "Aligned upstream displacement: dark = recessed joint", 544, 16),
        (Image.fromarray(mask), "Linear mask: black = protected, white = safe donor", 16, 568),
        (overlay, "Cyan = protected + feather; brick interior remains visible", 544, 568),
    ]:
        draw.text((x, y), label, fill="white")
        sheet.paste(image.convert("RGB").resize((496, 496), Image.Resampling.LANCZOS), (x, y + 24))
    sheet.save(docs / "source-mask-review.png")
    metadata = {
        "asset": "brick_4_interior_mask.png", "author": "Derived by godot-hex-detiling preprocessing",
        "license": "CC0-1.0", "upstream_author": "Rob Tuytel",
        "upstream_asset": "https://polyhaven.com/a/brick_4",
        "license_url": "https://polyhaven.com/license",
        "discovery_api": "https://api.polyhaven.com/files/brick_4",
        "source_url": URL, "source_bytes": len(raw), "source_md5": MD5,
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "mask_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "algorithm": "height > threshold; Euclidean distance to unsafe on 3x3 repeated image; crop center; smoothstep(guard, guard+feather, distance); round to uint8",
        "height_threshold_8bit": HEIGHT_THRESHOLD, "guard_pixels": GUARD_PIXELS,
        "feather_pixels": FEATHER_PIXELS, "size": [1024, 1024],
        "coverage": {"protected_zero": float((mask == 0).mean()), "full_interior": float((mask == 255).mean()), "mean_weight": float(mask.mean()/255)},
    }
    (docs / "source-mask.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata["coverage"], indent=2))


if __name__ == "__main__":
    main()
