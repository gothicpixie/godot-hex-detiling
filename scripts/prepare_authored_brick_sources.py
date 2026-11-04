#!/usr/bin/env python3
"""Prepare pinned CC0 maps and reviewed source-specific brick masks.

This is an authored material recipe, not a general brick recognizer. Requires
Pillow, NumPy, SciPy and OpenCV (to retain gray+alpha PNG height precision).
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import gaussian_filter, distance_transform_edt

from prepare_individual_brick_atlas import torus_labels, annotate
from pack_guard_albedo import pack

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(entry, assets, evidence, cache):
    name = entry["id"]
    output = evidence / name
    output.mkdir(parents=True, exist_ok=True)
    paths = {}
    map_records = {}
    for channel, metadata in entry["maps"].items():
        destination = assets / f"{name}_{channel}.{metadata['extension']}"
        cached = cache / name / ("albedo.jpg" if channel == "albedo" else f"{channel}.{metadata['extension']}") if cache else None
        if cached and cached.exists():
            raw = cached.read_bytes()
        elif destination.exists():
            raw = destination.read_bytes()
        else:
            result = subprocess.run(["curl", "-fsSL", "-A", "godot-hex-detiling-source-preparation/0.8 (CC0 brick validation)", metadata["url"]], check=True, capture_output=True)
            raw = result.stdout
        if len(raw) != metadata["bytes"] or hashlib.md5(raw).hexdigest() != metadata["md5"]:
            raise ValueError(f"Pinned upstream bytes/hash mismatch: {name}/{channel}")
        if destination.exists() and destination.read_bytes() != raw:
            raise ValueError(f"Refusing to overwrite existing source: {destination}")
        destination.write_bytes(raw)
        paths[channel] = destination
        map_records[channel] = {**metadata, "path": str(destination.relative_to(ROOT)), "sha256": sha(destination)}
    rgb = np.asarray(Image.open(paths["albedo"]).convert("RGB"))
    height = cv2.imread(str(paths["height"]), cv2.IMREAD_UNCHANGED)
    if height is None or height.dtype != np.uint16:
        raise ValueError("Expected exact 16-bit matching height PNG")
    if height.ndim == 3:
        assert np.array_equal(height[..., 0], height[..., 1]) and np.array_equal(height[..., 1], height[..., 2])
        # Upstream gray+alpha may contain quantization-sized deviations from
        # full opacity. Height is the independent gray data, never multiplied.
        assert np.all(height[..., 3] >= 65530)
        height = height[..., 0]
    if rgb.shape[:2] != height.shape or height.shape != (1024, 1024):
        raise ValueError("Expected aligned native 1K maps")
    for path in paths.values():
        assert Image.open(path).size == (1024, 1024)
    params = entry["mask_parameters"]
    height = height.astype(np.float64)
    residual = gaussian_filter(height, params["height_small_sigma"], mode="wrap")-gaussian_filter(height, params["height_broad_sigma"], mode="wrap")
    safe = residual > params["height_residual_threshold"]
    if params["red_excess_threshold"] is not None:
        color = rgb.astype(np.float64)
        excess = color[..., 0]-(color[..., 1]+color[..., 2])/2
        safe &= gaussian_filter(excess, 1.0, mode="wrap") > params["red_excess_threshold"]
    distances = distance_transform_edt(np.tile(safe, (3, 3)))[1024:2048, 1024:2048]
    t = np.clip((distances-params["edge_guard_pixels"])/params["feather_pixels"], 0, 1)
    mask = np.rint(255*t*t*(3-2*t)).astype(np.uint8)
    labels = torus_labels(mask > 0)
    areas = np.bincount(labels.ravel())
    discarded = np.flatnonzero(areas < params["minimum_component_pixels"])
    mask[np.isin(labels, discarded)] = 0
    for x0, y0, x1, y1 in params.get("preserve_original_rectangles", []):
        mask[y0:y1, x0:x1] = 0
    labels = torus_labels(mask > 0)
    mask_path = assets / f"{name}_interior_mask.png"
    Image.fromarray(mask).save(mask_path)
    packed_path = assets / f"{name}_albedo_guard.png"
    packing = pack(paths["albedo"], mask_path, packed_path)
    for channel, path in [("albedo", paths["albedo"]), ("mask", mask_path), ("output", packed_path)]:
        packing[channel]["path"] = str(path.relative_to(ROOT))
    annotate(rgb, labels, output / "source-segmentation.png")
    Image.fromarray(labels).save(output / "source-region-ids.png")
    height_preview = np.rint(255*np.clip((height-np.percentile(height, 1))/(np.percentile(height, 99)-np.percentile(height, 1)), 0, 1)).astype(np.uint8)
    overlay = rgb.copy()
    protected = mask == 0
    overlay[protected] = np.rint(.35*rgb[protected]+.65*np.array([0, 180, 255])).astype(np.uint8)
    sheet = Image.new("RGB", (1056, 1120), "#151c22")
    draw = ImageDraw.Draw(sheet)
    for i, (array, title) in enumerate([(rgb, "Original source RGB"), (height_preview, "Matching 16-bit height (display range only)"), (mask, "Authored conservative linear mask"), (overlay, "Cyan: exact-RGB protected pixels")]):
        x, y = 16+(i%2)*520, 16+(i//2)*552
        draw.text((x, y), title, fill="white")
        sheet.paste(Image.fromarray(array).convert("RGB").resize((504, 504)), (x, y+24))
    sheet.save(output / "source-mask-review.png")
    provenance = {
        **entry, "maps": map_records, "mask": str(mask_path.relative_to(ROOT)), "mask_sha256": sha(mask_path),
        "mask_regions": int(labels.max()), "protected_zero_fraction": float((mask==0).mean()),
        "fully_eligible_fraction": float((mask==255).mean()),
        "discarded_subthreshold_components": len(discarded),
        "mask_recipe": "Source-authored, reviewed thresholds on smoothed-minus-broad matching linear height; optional specified source RGB red-excess test; wrapped Euclidean guard/feather; discard small fragments. No roughness-as-height or ideal brick grid.",
        "height_decode": "OpenCV unchanged uint16; gray+alpha validated equal RGB/nearly-opaque alpha; independent gray data retained at16bits, no premultiplication",
        "packing": packing,
    }
    (output / "source-provenance.json").write_text(json.dumps(provenance, indent=2)+"\n")
    print(name, "regions", int(labels.max()), "protected", provenance["protected_zero_fraction"], flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT/"docs/brick_atlas_release/material-sources.json")
    parser.add_argument("--cache", type=Path)
    parser.add_argument("--assets", type=Path, default=ROOT/"assets/gallery")
    parser.add_argument("--evidence", type=Path, default=ROOT/"docs/brick_atlas_release/materials")
    args = parser.parse_args()
    args.assets.mkdir(parents=True, exist_ok=True)
    for entry in json.loads(args.manifest.read_text()):
        prepare(entry, args.assets, args.evidence, args.cache)


if __name__ == "__main__":
    main()
