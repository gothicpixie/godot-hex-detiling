"""CPU-only descriptive source-pattern calibration (Pillow + NumPy).

Run from repository root: python3 docs/structure/analysis/analyze_sources.py
The correlations describe integer translations of these source images, not a
rendered-output quality score. Texture repeat is modeled with numpy.roll.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
NAMES = ('brick_4', 'dark_wooden_planks', 'checkered_pavement_tiles')
SHIFTS = {
    'brick_4': [(136, 0), (68, 73), (0, 146), (0, 73), (128, 128), (341, 241)],
    'dark_wooden_planks': [(128, 0), (256, 0), (512, 0), (0, 114), (256, 128), (341, 241)],
    'checkered_pavement_tiles': [(205, 0), (102, 102), (102, 0), (128, 128), (341, 241)],
}


def corr(a, b):
    return round(float(np.corrcoef(a.ravel(), b.ravel())[0, 1]), 6)


result = {}
for name in NAMES:
    maps = {kind: Image.open(ROOT / 'assets/gallery' / f'{name}_{kind}.jpg')
            for kind in ('albedo', 'normal', 'roughness')}
    albedo = np.asarray(maps['albedo'], dtype=float).mean(axis=2)
    rough = maps['roughness'].convert('L')
    rr = np.asarray(rough, dtype=float)
    # Local positive contrast highlights light mortar/seams, then a modest
    # spatial tolerance accounts for hand-built edge wobble. This is a proxy,
    # not a semantic segmentation or a universal perceptual metric.
    contrast = np.maximum(rr - np.asarray(rough.filter(ImageFilter.GaussianBlur(8)), dtype=float), 0)
    edges = np.asarray(Image.fromarray(np.uint8(np.clip(contrast * 3, 0, 255)))
                       .filter(ImageFilter.GaussianBlur(3)), dtype=float)
    entry = {'map_dimensions': {k: list(im.size) for k, im in maps.items()}, 'shifts': []}
    for x, y in SHIFTS[name]:
        shifted_edges = np.roll(edges, (y, x), axis=(0, 1))
        shifted_albedo = np.roll(albedo, (y, x), axis=(0, 1))
        entry['shifts'].append({
            'xy_pixels': [x, y], 'roughness_line_correlation': corr(edges, shifted_edges),
            'albedo_gray_correlation': corr(albedo, shifted_albedo),
            'albedo_gray_mean_absolute_difference_0_255': round(float(np.abs(albedo - shifted_albedo).mean()), 6),
        })
    entry['roughness_gradient_profile_autocorrelation'] = {}
    for axis, label in ((0, 'y'), (1, 'x')):
        profile = np.abs(np.roll(rr, -1, axis=axis) - rr).mean(axis=1-axis)
        spectrum = np.fft.fft(profile - profile.mean())
        ac = np.fft.ifft(spectrum * np.conj(spectrum)).real
        ac /= ac[0]
        peaks = []
        for lag in np.argsort(ac[10:513])[::-1] + 10:
            if all(abs(int(lag) - p['pixels']) > 8 for p in peaks):
                peaks.append({'pixels': int(lag), 'correlation': round(float(ac[lag]), 6)})
            if len(peaks) == 5:
                break
        entry['roughness_gradient_profile_autocorrelation'][label] = peaks
    result[name] = entry
print(json.dumps(result, indent=2))
