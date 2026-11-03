#!/usr/bin/env python3
"""Create an opaque packed albedo COPY with bounded broad luminance correction.

Requires Pillow, NumPy and SciPy. The alpha data and all pixel positions remain
unchanged. RGB is decoded from sRGB, corrected in linear light, and re-encoded.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import scipy
from PIL import Image, ImageDraw, __version__ as pillow_version
from scipy.ndimage import gaussian_filter


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def linear(rgb):
    return np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)


def srgb(rgb):
    return np.where(rgb <= 0.0031308, rgb * 12.92, 1.055 * rgb ** (1 / 2.4) - 0.055)


def normalize(rgba, sigma=64.0, strength=0.65):
    rgb = linear(rgba[..., :3].astype(np.float64) / 255)
    luminance = rgb @ np.array([0.2126, 0.7152, 0.0722])
    broad = gaussian_filter(luminance, sigma=sigma, mode="wrap")
    target = float(np.exp(np.mean(np.log(np.maximum(broad, 1e-8)))))
    raw_gain = np.exp(strength * (np.log(target) - np.log(np.maximum(broad, 1e-8))))
    gain = np.clip(raw_gain, 0.85, 1.18)
    # One global exposure factor preserves a smooth gain field and avoids any
    # pixelwise clipping at existing bright specks. Do not clamp RGB highlights.
    exposure = min(1.0, 1.0 / float(np.max(rgb * gain[..., None])))
    gain *= exposure
    corrected = rgb * gain[..., None]
    if not np.isfinite(corrected).all() or corrected.min() < 0 or corrected.max() > 1:
        raise ValueError("Correction would leave finite linear RGB [0,1]; no clipping allowed")
    result = rgba.copy()
    result[..., :3] = np.rint(255 * srgb(corrected)).astype(np.uint8)
    decoded = linear(result[..., :3].astype(np.float64) / 255)
    new_lum = decoded @ np.array([0.2126, 0.7152, 0.0722])
    # Relative adjacent-pixel contrast in log light is insensitive to a constant
    # gain. Its small change measures the smooth gain field, not edge blur.
    log_before = np.log(np.maximum(luminance, 1e-6))
    log_after = np.log(np.maximum(new_lum, 1e-6))
    edge_before = np.concatenate([(np.roll(log_before, -1, axis)-log_before).ravel() for axis in (0, 1)])
    edge_after = np.concatenate([(np.roll(log_after, -1, axis)-log_after).ravel() for axis in (0, 1)])
    edge_pixels = np.abs(edge_before) > 0.10
    metrics = {
        "sigma_pixels": sigma, "strength": strength, "gain_bounds": [0.85, 1.18],
        "gain_actual": [float(gain.min()), float(gain.max())],
        "gain_clamped_fraction": float(np.mean((raw_gain < 0.85) | (raw_gain > 1.18))),
        "global_highlight_headroom_exposure": exposure,
        "relative_broad_luminance_std_before_after": [float(broad.std()/luminance.mean()), float(gaussian_filter(new_lum, sigma=sigma, mode="wrap").std()/new_lum.mean())],
        "out_of_range_or_clipped_samples": 0, "finite": True,
        "broad_luminance_std_before": float(broad.std()),
        "broad_luminance_std_after": float(gaussian_filter(new_lum, sigma=sigma, mode="wrap").std()),
        "linear_luminance_mean_before_after": [float(luminance.mean()), float(new_lum.mean())],
        "linear_luminance_percentiles_before": np.percentile(luminance, [1, 5, 50, 95, 99]).tolist(),
        "linear_luminance_percentiles_after": np.percentile(new_lum, [1, 5, 50, 95, 99]).tolist(),
        "adjacent_log_luminance_edge_correlation": float(np.corrcoef(edge_before, edge_after)[0, 1]),
        "strong_edge_sign_agreement": float(np.mean(np.sign(edge_before[edge_pixels]) == np.sign(edge_after[edge_pixels]))),
        "median_strong_edge_contrast_ratio": float(np.median(np.abs(edge_after[edge_pixels]) / np.abs(edge_before[edge_pixels]))),
        "max_adjacent_gain_difference": max(float(np.max(abs(np.roll(gain, -1, axis)-gain))) for axis in (0, 1)),
        "alpha_exact": bool(np.array_equal(result[..., 3], rgba[..., 3])),
        "no_warp_or_resampling": True,
    }
    return result, metrics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--sigma", type=float, default=64.0)
    parser.add_argument("--strength", type=float, default=0.65)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    if args.output.resolve() == args.source.resolve():
        parser.error("Output must be a separate copy")
    if not np.isfinite(args.sigma) or args.sigma <= 0 or not 0 <= args.strength <= 1:
        parser.error("Sigma must be positive; strength must be within [0,1]")
    source_hash = digest(args.source)
    with Image.open(args.source) as image:
        if image.mode != "RGBA":
            raise ValueError("Expected packed 8-bit RGBA source")
        original = np.asarray(image).copy()
    result, metrics = normalize(original, args.sigma, args.strength)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(result).save(args.output, compress_level=9)
    with Image.open(args.output) as image:
        assert np.array_equal(np.asarray(image), result)
    assert source_hash == digest(args.source)
    args.evidence.mkdir(parents=True, exist_ok=True)
    provenance = {
        "source": str(args.source), "source_sha256": source_hash,
        "output": str(args.output), "output_sha256": digest(args.output),
        "alpha_sha256": hashlib.sha256(result[..., 3].tobytes()).hexdigest(),
        "size": list(result.shape[1::-1]), "inputs_unchanged": True,
        "license": "CC0-1.0", "upstream_author": "Rob Tuytel / Poly Haven",
        "libraries": {"pillow": pillow_version, "numpy": np.__version__, "scipy": scipy.__version__},
        "upstream_asset": "https://polyhaven.com/a/brick_4",
        "algorithm": "sRGB decode; wrapped Gaussian of linear Rec709 luminance; geometric-mean target; scalar exp(strength*log(target/broad)) gain bounded0.85..1.18 before one global highlight-headroom exposure; multiply original linear RGB; sRGB encode/round without RGB clipping; copy alpha exactly",
        "metrics": metrics,
    }
    (args.evidence / "normalized-albedo.json").write_text(json.dumps(provenance, indent=2)+"\n")
    # These previews show RGB alone: alpha is mask data, not transparency.
    variants = [("Original", original)]
    for value in (0.4, 0.65, 0.8):
        candidate, m = normalize(original, args.sigma, value)
        variants.append((f"Strength {value:.2f} / broad std {m['broad_luminance_std_after']:.5f}", candidate))
    sheet = Image.new("RGB", (1056, 1144), "#161c21")
    draw = ImageDraw.Draw(sheet)
    for i, (label, array) in enumerate(variants):
        x, y = 16 + (i % 2)*520, 16 + (i // 2)*564
        draw.text((x, y), label, fill="white")
        sheet.paste(Image.fromarray(array[..., :3]).resize((504, 504)), (x, y+24))
    sheet.save(args.evidence / "normalization-candidates.jpg", quality=95)
    print(json.dumps(provenance, indent=2))


if __name__ == "__main__":
    main()
