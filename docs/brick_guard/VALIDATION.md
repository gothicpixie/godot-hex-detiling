# Brick mortar guard validation

Validated 2026-11-03 on Apple M5, Godot 4.7.2 stable, OpenGL 4.1 Metal Compatibility. No shader compiler errors or failed assertions in final logs.

## Results

- `red.log` records the expected initial failure before the opt-in uniform existed.
- `probe.log`: compiled production helper passes black reference preservation across color, nonflat normal, roughness; white interior variation; common color/roughness weights; normalized bounded compiled weights at four mask levels; forced black donor rejection; deterministic seeds; disabled old-helper baseline; missing map fallback; coarse footprint fallback; continuous mask boundary.
- Direct projected actual-source probe: 14,492 sampled black-mask pixels have zero observed color, normal, and roughness error against original sampling in RGBA8 readback. This is quantized observed agreement, not floating-point equality. 16,648 white-mask interior pixels have mean color L2 difference 0.104976. The diagnostic explicitly uses the actual brick preset (period 2/15 × 1/14, stagger 0.5, seed 0), a 192×192 projected probe, and derivatives 0.0003 per axis, corresponding to a near-view mask footprint of 0.3072 texels. The gallery views have larger and spatially varying footprints, so this number does not describe their average variation. Exact settings and results are saved in `actual-source-metrics.json`. This measures supplied mask-black pixels; it does not establish that every actual mortar pixel is classified black.
- `full-baseline.log`: full spatial shader, including final triplanar fragment, matches frozen `6c9cabf` with guard disabled: maximum rendered RGB difference 0 for structure off/on and seeds 0/7.
- `smoke.log`, `ui-smoke.log`, `structure-smoke.log`, `gpu-probe.log`, `coherent-probe.log`, and `structure-probe.log` pass. UI test verifies brick eligibility, preference persistence, mask binding/clearing, unsupported reset, disabled blend selection while the coherent guard overrides it, and restored previous blend selection/flags when the guard is disabled. Historical structure probe now loads its matching historical coherent include, avoiding a baseline made from incompatible versions.

## Native captures

`capture-settings.json` records exact cameras and render settings. Eighteen original 1280×720 PNGs cover wall, oblique, and elevated terrain; periodic, existing structured, and guarded; seeds 0 and 7. Lighting, texture scale 2.5 m, normal strength 0.8, roughness, blend contrast 0.65, and zero detrending are matched. The structured captures explicitly disable the new guard.

`native-comparison-seed0.jpg` and `native-comparison-seed7.jpg` contain identical 400×300 native pixel crops, without resizing or color changes. `wall-loop-seed0.gif` and `wall-loop-seed7.gif` cycle periodic → existing structured → guarded at 1.4 seconds per frame; GIF palette quantization applies, so use PNGs for exact inspection.

Visual inspection of both seeds: existing structured blends show crossing or softened mortar; guarded captures retain the reference mortar geometry with interior color changes and no obvious new hard mask boundaries. The guarded result keeps visible source repetitions. At the oblique and elevated views, footprint fallback reduces donor participation; preservation takes priority over strong variation. The actual source probe demonstrates nonzero interior variation but is not an estimate of variation for every screenshot footprint.

## Cost

`benchmark.log` contains three alternating rounds, 60 warmup and 180 measured frames per mode per round, 1280×720, UI hidden, identical demo terrain. Existing structured mode median whole-frame times: 3.432, 3.421, 3.452 ms. Guarded: 5.607, 5.681, 5.590 ms. Mean of round medians increases from 3.435 to 5.626 ms, about 63.8%. These are whole-frame wall times, not GPU timings; Godot returned zero GPU timer samples. This is a single-device result and includes frame scheduling overhead.

The guarded path adds four mask reads and three reference PBR reads per triplanar projection with roughness enabled, plus source texture-size/weight arithmetic. It uses the common coherent path when active. Far fallback currently reduces contribution, not texture-fetch count.

## Reproduction

Run from the repository root. First freeze baseline files and import resources:

```sh
git show 6c9cabf:addons/hex_detile/hex_detile.gdshader > /tmp/hex-brick-guard-baseline.gdshader
git show 6c9cabf:addons/hex_detile/coherent_blend.gdshaderinc > /tmp/hex-brick-guard-baseline.gdshaderinc
git show 5b86dca:addons/hex_detile/hex_detile.gdshader > /tmp/hex-structure-baseline.gdshader
git show 5b86dca:addons/hex_detile/coherent_blend.gdshaderinc > /tmp/hex-structure-baseline.gdshaderinc
/opt/homebrew/bin/godot --headless --editor --path . --import
```

For GPU runs use the following flags and substitute the test path listed above. Run GPU tasks sequentially:

```sh
/opt/homebrew/bin/godot --path . --rendering-method gl_compatibility --disable-vsync --always-on-top --script tests/brick_guard_probe.gd
/opt/homebrew/bin/godot --path . --rendering-method gl_compatibility --disable-vsync --always-on-top --script tests/brick_guard_baseline.gd
/opt/homebrew/bin/godot --path . --rendering-method gl_compatibility --disable-vsync --always-on-top --script tests/brick_guard_gallery.gd
/opt/homebrew/bin/godot --path . --rendering-method gl_compatibility --disable-vsync --always-on-top --script benchmarks/brick_guard_compare.gd
```

Use `--headless --path . --script` for the three smoke tests. Generate the comparison media with a Python environment containing Pillow: `python tests/brick_guard_media.py`.
