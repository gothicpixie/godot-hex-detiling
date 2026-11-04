# Additional prepared sources and projection limits

**Both additional sources fail the complete predeclared appearance gate and remain controlled examples, not newly qualified supported presets.** Color repetition improves and protected mortar is preserved, but the luminance-correlation target is missed. Red Brick also narrowly misses the rendered palette-variance floor. No thresholds were rounded or waived, and no further tuning was attempted.

Actual CC0 Red Brick and Large Red Bricks sources use matching albedo/normal/roughness/height, authored source-specific mortar masks, native 1024² source tiles, and 4×4 atlases. Full provenance/import/palette/segmentation audits are under `materials/<source>/`. They were appended at stable indices 17/18 as `supported=false`. The evaluator reads production `BRICK_PRESETS`, `TEXTURE_SETS` and `STRUCTURE_PRESETS` and explicitly overrides eligibility only for these controlled captures. Production source shader, squared weights, offsets, filters and physical input coordinates were unchanged.

## Finite comparison

Seed 0 only for this expansion. Physical source scales 1.4 m/2 m. Two unlit orthographic wall heights 3×/12× source scale produce the same known 240 px/60 px source-repeat displacement as stage 1. Four original/candidate wall captures per source, plus close wall/corner/cylinder PBR pairs, give 20 static cases total. One 12-pose matched cylinder orbit per source adds 24 matched camera poses/48 images. Actual camera correspondence is audited in `material-motion-audit.json`; raw moving-image differences are not used as flicker measurements.

The same original distant targets were declared before capture: chromatic periodic energy ratio ≤0.50, chromatic correlation ≤0.60, luminance correlation ≤0.75, rendered between-brick RGB palette variance ≥0.50 and mean brightness ±10%. Opponent channels R-G/B-G, Gaussian suppression of intended brick pitch, exact source lags and raw phase-energy numerators follow stage 1. Absolute values accompany ratios, so low-contrast input does not earn an automatic pass.

| Distant source | Color periodic energy ratio | Color correlation ratio | Luminance correlation ratio | Between-brick RGB variance ratio | Strict result |
|---|---:|---:|---:|---:|---|
| Red Brick |0.263|0.559|0.832|0.49796|FAIL: luminance and palette|
| Large Red Bricks |0.147|0.592|0.76394|0.51087|FAIL: luminance|

Thus measured color periodic energy falls 73.7%/85.3%, but luminance correlation falls only 16.8%/23.6%, below the 25% target. Red Brick's 49.796% palette retention is below 50%, not rounded up. Original/candidate absolute opponent-color variance is 0.001999/0.001578 for Red Brick and 0.003249/0.002360 for Large Red Bricks; neither input is near the 1e-8 numerical-warning floor. Mean luminance ratios 0.99145/1.00093 are within limits. Near-wall values and absolute per-brick/channel variances remain in `material-metrics.json`.

Native preprocessing audits report exact repeated alpha and protected RGB, toroidal connected-region continuity, preserved source coordinates and matching source PBR. Fine-detail core correlations exceed 0.99, with standard-deviation ratios approximately 1.003–1.008. This supports retention of input grain, not global equality of the recolored result.

## Mortar and geometry

In close wall, corner and cylinder captures, exact production alpha = 0 protected shaded RGB differs by at most 1/255, and protected normal/roughness match exactly for both sources. The curved classifier requires every non-negligibly contributing projection to have zero source alpha. Full-image color changes are intentional. This is a bounded per-projection preservation result, not a claim that every filtered boundary pixel or edge contrast is unchanged.

Native wall and shape comparisons show aligned joint locations without an additional doubled joint introduced by the candidate in the inspected views. Corners and cylinders still inherit triplanar projection mixing: brick courses need not wrap continuously around a corner or curve, and fine source weathering/layout still repeats. Original/candidate side-by-side images expose that limitation; per-projection phase preservation cannot establish a globally authored brick topology. The interactive shape selector is therefore a useful inspection tool, not a guarantee of seamless masonry on arbitrary geometry.

Inspectable files:

- `red_brick-wall-12.0-native.png`, `large_red_bricks-wall-12.0-native.png`: distant native pairs.
- `<source>-close-native.png`: close mortar/detail pairs without resizing.
- `<source>-corner-pbr.png`, `<source>-cylinder-pbr.png`: shape comparisons.
- `red_brick-orbit.gif`, `large_red_bricks-orbit.gif`: actual matched cylinder motion.

## Reproduction

With prepared assets and their checked-in `.import` settings present, run sequential GPU commands from the repository root:

```sh
/opt/homebrew/bin/godot --headless --path . --editor --import
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script tests/atlas_release_materials.gd
uv run --with pillow --with numpy --with scipy python tests/atlas_release_material_analysis.py
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 640x360 --script tests/atlas_release_materials.gd -- --motion
uv run --with pillow python tests/atlas_release_material_motion.py
```

These outcomes broaden the evidence, not the qualified preset set. Brick 4 with the accepted 4×4 atlas remains the supported quality reference.
