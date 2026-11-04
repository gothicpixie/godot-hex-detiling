#!/usr/bin/env python3
"""Bake finite toroidal atlases with independently assigned source brick colors.

Requires Pillow, NumPy, SciPy. Input RGB/alpha are not resized or warped. Connected
regions are detected on the entire atlas, including all internal/outer seams.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import scipy
from PIL import Image, ImageDraw, __version__ as pillow_version
from scipy.ndimage import label, gaussian_filter


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def linear(rgb):
    return np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4)


def srgb(rgb):
    return np.where(rgb <= .0031308, rgb * 12.92, 1.055 * rgb ** (1 / 2.4) - .055)


def torus_labels(safe):
    regions, count = label(safe)  # Four-neighbor, actual authored interior topology.
    parent = np.arange(count + 1)

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a, b):
        if a and b:
            parent[find(b)] = find(a)

    for a, b in zip(regions[0], regions[-1]):
        union(a, b)
    for a, b in zip(regions[:, 0], regions[:, -1]):
        union(a, b)
    lookup = np.array([find(i) for i in range(count + 1)])
    regions = lookup[regions]
    roots = np.unique(regions)
    remap = np.zeros(count + 1, dtype=np.uint16)
    remap[roots] = np.arange(len(roots), dtype=np.uint16)
    return remap[regions]


def grouped_indices(labels):
    flat = labels.ravel()
    order = np.argsort(flat, kind="stable")
    counts = np.bincount(flat)
    ends = np.cumsum(counts)
    return [order[end-count:end] for count, end in zip(counts, ends)]


def annotate(rgb, labels, output):
    rng = np.random.default_rng(71)
    colors = rng.integers(50, 245, (int(labels.max()) + 1, 3))
    overlay = rgb.copy()
    safe = labels > 0
    overlay[safe] = np.rint(.45 * rgb[safe] + .55 * colors[labels[safe]]).astype(np.uint8)
    image = Image.fromarray(overlay)
    draw = ImageDraw.Draw(image)
    for region, indices in enumerate(grouped_indices(labels)):
        if region == 0 or not len(indices):
            continue
        index = int(indices[len(indices)//2])
        y, x = divmod(index, labels.shape[1])
        draw.text((x, y), f"{region}:{len(indices)}", fill="white", stroke_width=1, stroke_fill="black")
    image.save(output)


def balance_palette(targets, active, source_ids, bases, seed):
    """Swap whole target assignments; preserve exact palette multiplicities."""
    palette_ids = np.array(sorted(bases))
    palette = np.array([bases[int(i)] for i in palette_ids])
    center = palette.mean(axis=0)
    covariance = np.cov(palette, rowvar=False, bias=True)
    ridge = .1 * np.trace(covariance)/3
    eigenvalues, eigenvectors = np.linalg.eigh(covariance)
    whitening = eigenvectors @ np.diag(1/np.sqrt(eigenvalues+ridge))
    whitened = {int(i): (bases[int(i)]-center) @ whitening for i in palette_ids}
    group_ids = sorted({source_ids[i] for i in active})
    groups = [np.array([j for j, region in enumerate(active) if source_ids[region] == i]) for i in group_ids]
    group_of = np.zeros(len(targets), dtype=int)
    for group, indices in enumerate(groups):
        group_of[indices] = group

    def sums_for(values):
        return np.array([sum((whitened[int(values[i])] for i in indices), np.zeros(3)) for indices in groups])

    def duplicates(values):
        return sum(len(indices)-len(set(values[indices])) for indices in groups)

    def score(values):
        means = np.array([np.mean([bases[int(values[i])] for i in indices], axis=0) for indices in groups])
        sums = sums_for(values)
        return {
            "whitened_mean_bias_score": float(np.mean([np.dot(row, row)/len(indices)**2 for row, indices in zip(sums, groups)])),
            "per_source_target_mean_rgb_variance": means.var(axis=0).tolist(),
            "per_source_target_mean_rgb_variance_sum": float(means.var(axis=0).sum()),
            "duplicate_palette_choices_within_source_groups": int(duplicates(values)),
        }

    result = targets.copy()
    before = score(result)
    sums = sums_for(result)
    rng = np.random.default_rng(seed+71093)
    accepted = 0
    duplicate_penalty = 20.0
    for a, b in rng.integers(0, len(result), (250000, 2)):
        ga, gb = group_of[a], group_of[b]
        if ga == gb or result[a] == result[b]:
            continue
        av, bv = int(result[a]), int(result[b])
        ia, ib = groups[ga], groups[gb]
        old_duplicates = len(ia)-len(set(result[ia]))+len(ib)-len(set(result[ib]))
        result[a], result[b] = bv, av
        new_duplicates = len(ia)-len(set(result[ia]))+len(ib)-len(set(result[ib]))
        delta = whitened[bv]-whitened[av]
        change = 2*np.dot(sums[ga]-sums[gb], delta)+2*np.dot(delta, delta)
        change += duplicate_penalty*(new_duplicates-old_duplicates)
        if change < -1e-12:
            sums[ga] += delta
            sums[gb] -= delta
            accepted += 1
        else:
            result[a], result[b] = av, bv
    assert np.array_equal(np.sort(targets), np.sort(result))
    return result, {
        "method": "250000 deterministic random pair proposals; greedy whole-palette swaps across source-ID groups; covariance-whitened RGB mean-bias plus duplicate-choice penalty; exact global counts",
        "covariance_regularizer_fraction_average_channel_variance": .1,
        "covariance_regularizer_linear_rgb_variance": float(ridge),
        "accepted_swaps": accepted, "before": before, "after": score(result),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path("assets/gallery/brick_4_albedo_guard.png"))
    parser.add_argument("--tiles", type=int, default=4)
    parser.add_argument("--seeds", type=int, nargs="+", default=[0, 7])
    parser.add_argument("--name", default="brick_4_individual_atlas", help="Output filename stem, followed by _seedN.png")
    parser.add_argument("--balance-palette", action="store_true", help="Reduce per-source-ID color bias using deterministic palette swaps")
    parser.add_argument("--source-provenance", type=Path, help="Optional authored source-material provenance JSON")
    parser.add_argument("--assets", type=Path, default=Path("assets/gallery"))
    parser.add_argument("--evidence", type=Path, default=Path("docs/individual_brick"))
    args = parser.parse_args()
    if not 1 <= args.tiles <= 8:
        parser.error("Expected 1..8 whole source tiles per atlas dimension")
    with Image.open(args.source) as image:
        if image.mode != "RGBA":
            raise ValueError("Expected packed RGBA input")
        source = np.asarray(image).copy()
    source_hash = digest(args.source)
    source_labels = torus_labels(source[..., 3] > 0)
    source_groups = grouped_indices(source_labels)
    source_linear = linear(source[..., :3].astype(np.float64)/255)
    bases = {}
    ignored = []
    for region, indices in enumerate(source_groups):
        if region == 0:
            continue
        core = indices[source[..., 3].ravel()[indices] == 255]
        if len(indices) < 64 or len(core) < 64:
            ignored.append(region)
            continue
        bases[region] = np.median(source_linear.reshape(-1, 3)[core], axis=0)
    palette_ids = np.array(sorted(bases))
    # Smooth color identity within each actual brick, never across mortar. A
    # local field avoids boosting an old green/dark border into a colored ring.
    # Toroidal unwrapping keeps boundary-crossing source bricks whole.
    low_base = source_linear.copy()
    for region in palette_ids:
        indices = source_groups[region]
        yy, xx = np.divmod(indices, source.shape[1])
        uy = (yy-int(yy[0])+source.shape[0]//2) % source.shape[0]-source.shape[0]//2
        ux = (xx-int(xx[0])+source.shape[1]//2) % source.shape[1]-source.shape[1]//2
        uy -= uy.min(); ux -= ux.min()
        shape = (int(uy.max())+1, int(ux.max())+1)
        weights = np.zeros(shape)
        weights[uy, ux] = source[..., 3].ravel()[indices]/255
        denominator = gaussian_filter(weights, 12.0, mode="constant")
        for channel in range(3):
            values = np.zeros(shape)
            values[uy, ux] = source_linear.reshape(-1, 3)[indices, channel]*weights[uy, ux]
            smoothed = gaussian_filter(values, 12.0, mode="constant")/np.maximum(denominator, 1e-12)
            low_base.reshape(-1, 3)[indices, channel] = .8*smoothed[uy, ux]+.2*bases[region][channel]
    tiled = np.tile(source, (args.tiles, args.tiles, 1))
    labels = torus_labels(tiled[..., 3] > 0)
    groups = grouped_indices(labels)
    height, width = labels.shape
    source_height, source_width = source.shape[:2]
    source_ids = []
    for indices in groups:
        if not len(indices):
            source_ids.append(0)
            continue
        y, x = np.divmod(indices, width)
        ids = np.unique(source_labels[y % source_height, x % source_width])
        assert len(ids) == 1, "An atlas component joined different source brick IDs"
        source_ids.append(int(ids[0]))
    active = [region for region in range(1, len(groups)) if source_ids[region] in bases]
    expected = len(bases) * args.tiles**2
    assert len(active) == expected, (len(active), expected)
    assert np.all(labels[0][(labels[0]>0)&(labels[-1]>0)] == labels[-1][(labels[0]>0)&(labels[-1]>0)])
    assert np.all(labels[:,0][(labels[:,0]>0)&(labels[:,-1]>0)] == labels[:,-1][(labels[:,0]>0)&(labels[:,-1]>0)])
    args.evidence.mkdir(parents=True, exist_ok=True)
    args.assets.mkdir(parents=True, exist_ok=True)
    Image.fromarray(source_labels).save(args.evidence / "source-region-ids.png")
    Image.fromarray(labels).save(args.evidence / "atlas-region-ids.png")
    annotate(source[..., :3], source_labels, args.evidence / "source-segmentation.png")
    common = {
        "source": str(args.source), "source_sha256": source_hash,
        "license": "CC0-1.0", "upstream_author": "Rob Tuytel / Poly Haven",
        "upstream_asset": "https://polyhaven.com/a/brick_4",
        "libraries": {"pillow": pillow_version, "numpy": np.__version__, "scipy": scipy.__version__},
        "source_size": [source_width, source_height], "atlas_size": [width, height],
        "tiles_per_axis": args.tiles, "source_regions": len(source_groups)-1,
        "recolored_source_regions": len(bases), "ignored_tiny_source_regions": ignored,
        "atlas_regions": len(groups)-1, "recolored_atlas_regions": len(active),
        "palette": [{"source_region": region, "base_linear_rgb": bases[region].tolist()} for region in palette_ids.tolist()],
        "segmentation": "4-neighbor components of guard alpha>0 on full tiled atlas; union opposite outer boundaries; no ideal grid fit",
        "algorithm": "robust per-source-brick median RGB palette from alpha255 core; within-brick alpha-normalized Gaussian sigma12 linear RGB field (80% local field,20% region median) removes broad source color; balanced source palette shuffle per actual atlas component; per-channel target/localbase correction feathered by original alpha; highlight common-RGB scale only if necessary; original alpha0 RGB copied exactly",
        "within_brick_lowpass_sigma_pixels": 12.0,
        "within_brick_local_base_fraction": .8,
    }
    if args.source_provenance:
        material = json.loads(args.source_provenance.read_text())
        common["upstream_author"] = ", ".join(material["authors"])+" / Poly Haven"
        common["upstream_asset"] = material["source"]
        common["license"] = material["license"]
        common["source_material_id"] = material["id"]
        common["source_material_provenance"] = str(args.source_provenance)
        common["source_material_provenance_sha256"] = digest(args.source_provenance)
    seed_results = []
    for seed in args.seeds:
        rng = np.random.default_rng(seed)
        targets = np.tile(palette_ids, args.tiles**2)
        rng.shuffle(targets)
        balance = None
        if args.balance_palette:
            targets, balance = balance_palette(targets, active, source_ids, bases, seed)
        output = tiled.copy()
        output_flat = output.reshape(-1, 4)
        records = []
        overflow_count = 0
        max_unbounded = 0.0
        edge_contrast = []
        for region, target_id in zip(active, targets):
            indices = groups[region]
            source_id = source_ids[region]
            base, target = bases[source_id], bases[int(target_id)]
            pixels = tiled.reshape(-1, 4)[indices]
            original = linear(pixels[:, :3].astype(np.float64)/255)
            weight = pixels[:, 3].astype(np.float64)/255
            yy, xx = np.divmod(indices, width)
            local_base = low_base[yy % source_height, xx % source_width]
            gain = np.exp(weight[:, None] * np.log(target/local_base))
            corrected = original * gain
            maximum = corrected.max(axis=1)
            overflow = maximum > 1
            overflow_count += int(overflow.sum())
            max_unbounded = max(max_unbounded, float(maximum.max()))
            # Preserve RGB ratios instead of clipping individual channels on
            # the very sparse original bright specks that exceed the gamut.
            corrected /= np.maximum(maximum, 1)[:, None]
            assert np.isfinite(corrected).all() and corrected.min() >= 0 and corrected.max() <= 1
            encoded = np.rint(255 * srgb(corrected)).astype(np.uint8)
            output_flat[indices, :3] = encoded
            core = pixels[:, 3] == 255
            actual_base = np.median(linear(encoded[core].astype(np.float64)/255), axis=0)
            records.append({
                "atlas_region": region, "source_region": source_id,
                "palette_source_region": int(target_id), "pixels": len(indices),
                "base_linear_rgb": base.tolist(), "target_linear_rgb": target.tolist(),
                "actual_core_median_linear_rgb": actual_base.tolist(),
                "core_rgb_gain": (target/base).tolist(),
                "highlight_gamut_scaled_pixels": int(overflow.sum()),
                "touches_outer_x": bool(np.any(indices % width == 0) or np.any(indices % width == width-1)),
                "touches_outer_y": bool(np.any(indices // width == 0) or np.any(indices // width == height-1)),
            })
        assert np.array_equal(output[..., 3], tiled[..., 3])
        protected = tiled[..., 3] == 0
        assert np.array_equal(output[..., :3][protected], tiled[..., :3][protected])
        path = args.assets / f"{args.name}_seed{seed}.png"
        if path.resolve() == args.source.resolve():
            raise ValueError("Output must not overwrite source")
        Image.fromarray(output).save(path, compress_level=9)
        with Image.open(path) as image:
            assert np.array_equal(np.asarray(image), output)
        data = {
            "seed": seed, "asset": str(path), "sha256": digest(path),
            "alpha_sha256": hashlib.sha256(output[..., 3].tobytes()).hexdigest(),
            "protected_pixels_exact": int(protected.sum()), "alpha_all_pixels_exact": True,
            "no_coordinate_warp_or_resampling": True, "finite_and_in_gamut": True,
            "highlight_gamut_scaled_pixels": overflow_count,
            "highlight_gamut_scaled_fraction": overflow_count/(width*height),
            "maximum_pre_gamut_linear_channel": max_unbounded,
            "palette_assignment_balanced": bool(np.all(np.unique(targets, return_counts=True)[1] == args.tiles**2)),
            "source_mean_bias_optimization": balance,
            "regions": records,
        }
        (args.evidence / f"atlas-seed{seed}.json").write_text(json.dumps(data, indent=2)+"\n")
        seed_results.append({key: value for key, value in data.items() if key != "regions"})
        # Native close crop crosses an internal cell boundary. Whole-atlas
        # thumbnails are previews only; quantitative assets retain every pixel.
        preview = Image.new("RGB", (2048, 1080), "#151c22")
        draw = ImageDraw.Draw(preview)
        draw.text((8, 8), "Original repeating RGB", fill="white")
        draw.text((1032, 8), f"Per-brick RGB palette / seed {seed} / finite {args.tiles}x{args.tiles} atlas", fill="white")
        preview.paste(Image.fromarray(tiled[..., :3]).resize((1024, 1024)), (0, 30))
        preview.paste(Image.fromarray(output[..., :3]).resize((1024, 1024)), (1024, 30))
        preview.save(args.evidence / f"atlas-overview-seed{seed}.jpg", quality=95)
        crop = (slice(700, 1100), slice(700, 1340))
        native = Image.new("RGB", (1280, 430), "#151c22")
        draw = ImageDraw.Draw(native)
        draw.text((8, 8), "Original RGB / native / internal tile boundary at x=1024", fill="white")
        draw.text((648, 8), "Per-brick recolor / native / same coordinates", fill="white")
        native.paste(Image.fromarray(tiled[crop][..., :3]), (0, 30))
        native.paste(Image.fromarray(output[crop][..., :3]), (640, 30))
        native.save(args.evidence / f"source-native-seed{seed}.png")
        print(json.dumps(seed_results[-1]), flush=True)
    assert source_hash == digest(args.source)
    common["inputs_unchanged"] = True
    common["seeds"] = seed_results
    (args.evidence / "atlas-provenance.json").write_text(json.dumps(common, indent=2)+"\n")


if __name__ == "__main__":
    main()
