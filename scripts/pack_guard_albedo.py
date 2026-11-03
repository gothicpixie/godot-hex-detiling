#!/usr/bin/env python3
"""Losslessly pack decoded albedo RGB and an aligned 8-bit guard mask into RGBA.

Requires Pillow. Does not resize, premultiply, color-transform, or edit inputs.
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, __version__ as pillow_version


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pack(albedo_path, mask_path, output_path):
    inputs = (albedo_path.resolve(), mask_path.resolve())
    if output_path.resolve() in inputs:
        raise ValueError("Output must not overwrite either input")
    hashes = [sha256(path) for path in inputs]
    with Image.open(albedo_path) as source, Image.open(mask_path) as mask:
        if source.size != mask.size:
            raise ValueError(f"Aligned dimensions required: {source.size} != {mask.size}")
        if mask.mode != "L":
            raise ValueError(f"Expected an 8-bit single-channel L mask, got {mask.mode}")
        rgb = source.convert("RGB")
        alpha = mask.copy()
    packed = Image.merge("RGBA", (*rgb.split(), alpha))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    packed.save(output_path, format="PNG", optimize=False, compress_level=9)
    with Image.open(output_path) as check:
        if check.mode != "RGBA" or check.size != rgb.size:
            raise ValueError("Packed PNG format or dimensions changed")
        if check.convert("RGB").tobytes() != rgb.tobytes():
            raise ValueError("Packed RGB differs from decoded source RGB")
        if check.getchannel("A").tobytes() != alpha.tobytes():
            raise ValueError("Packed alpha differs from source mask")
    if [sha256(path) for path in inputs] != hashes:
        raise ValueError("Input files changed during packing")
    return {
        "albedo": {"path": str(albedo_path), "sha256": hashes[0]},
        "mask": {"path": str(mask_path), "sha256": hashes[1]},
        "output": {"path": str(output_path), "sha256": sha256(output_path)},
        "size": list(rgb.size), "mode": "RGBA", "pillow_version": pillow_version,
        "rgb_exact": True, "alpha_exact": True, "inputs_unchanged": True,
        "rgb_sha256": hashlib.sha256(rgb.tobytes()).hexdigest(),
        "alpha_sha256": hashlib.sha256(alpha.tobytes()).hexdigest(),
        "algorithm": "Decode albedo to RGB; copy L mask to alpha; save RGBA PNG; verify every channel byte including RGB at alpha=0",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("albedo", type=Path)
    parser.add_argument("mask", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--provenance", type=Path)
    args = parser.parse_args()
    if args.provenance and args.provenance.resolve() in {
        args.albedo.resolve(), args.mask.resolve(), args.output.resolve()
    }:
        parser.error("Provenance must not overwrite an input or packed image")
    result = pack(args.albedo, args.mask, args.output)
    text = json.dumps(result, indent=2) + "\n"
    if args.provenance:
        args.provenance.parent.mkdir(parents=True, exist_ok=True)
        args.provenance.write_text(text)
    print(text, end="")


if __name__ == "__main__":
    main()
