# Distant brick experiment: partial improvement, overall target FAIL

The candidate removes about51% of the measured mean-normalized low-frequency periodic tonal energy at distance, but the repeated brick/weathering pattern remains visible. It does **not** meet the predeclared20% full-source autocorrelation reduction target. Mortar edges remain visually aligned in native crops; the edge-profile and protected material-channel measurements support that limited observation. This is a useful opt-in comparison, not a solved distant-tiling mode.

Reference: full v0.7.0 shader and matching coherent helper frozen from6732aff6 before edits, in `fixtures/`. All GPU work used `/opt/homebrew/bin/godot`, Godot4.7.2 official `ed1daf0bf`, AppleM5, Compatibility OpenGL4.1/Metal90.5. Images use RGBA8 readback. The render loop was disabled and each capture explicitly rendered twice with `RenderingServer.force_draw(false)` after process-frame updates. UI hidden; fixed light/environment/camera per comparison. No benchmark or release was run.

## Four-arm result

16 unlit orthographic images cover2 distances×2 seeds×4 arms. The wall fills the image. Source scale2.5m; view heights7.5m and30m. Actual `Camera3D.unproject_position` measurements give full-source repeat displacements240px and60px respectively. Analysis uses those known displacements, not a selected image-spectrum peak.

Linear luminance is blurred with sigma=source-repeat-pixels/32. The image is cropped to whole source periods. Absolute periodic energy sums the raw squared Fourier coefficients at full-source harmonics1..6 in x/y, excluding DC and the intended finer brick lattice. This numerator is also divided by mean-luminance squared; extra macro variance is never the denominator of the success criterion. Mean, variance, raw energy and normalized energy are retained in `metrics.json`.

Distant ratios relative to the same-seed baseline:

| Arm | Periodic energy / mean², seed0 | Seed7 | Full-source autocorrelation ratio, seed0 | Seed7 |
|---|---:|---:|---:|---:|
| Normalization only |0.490|0.490|0.998|0.998|
| Macro only |1.000|0.997|0.904|0.910|
| Both |0.492|0.490|0.877|0.886|

Normalization produces a real decrease in the periodic tonal numerator. It remains a repeating normalized texture, hence its autocorrelation stays almost unchanged. Macro alone mainly adds broad variation: it lowers normalized correlation while leaving the periodic numerator essentially unchanged. Combined improvement is visible as gentler tonal patch repetition, but recognizable repeated green/dark brick details remain.

Autocorrelation is Pearson correlation at one complete source repeat separately in x/y, followed by the arithmetic mean of the two axes. The reported ratio divides that candidate mean by the corresponding baseline mean. Baseline mean0.998296; combined means0.875334/0.884465 for seeds0/7. Thus reductions are12.317%/11.402%, below the predeclared20% target. This aggregation is not an FFT-energy ratio or a raw moving-frame difference.

Intermediate combined periodic energy ratios0.449/0.443 improve; mean linear luminance ratios0.942/0.899916 reveal seed-dependent darkening. Seed7 marginally exceeds the declared10% brightness-loss limit. Distant combined mean ratios0.968/0.960 stay within it. The normalized asset's approximately4.2% lower mean is disclosed rather than credited as repetition removal. No unlit orthographic arm contained an output pixel with any channel saturated at255; this does not exclude rare highlights elsewhere or establish that all possible macro gains remain in gamut.

## Mortar and material channels

The normalized asset preserves the alpha mask byte-for-byte and changes RGB without resampling or geometric warping; source validation is in `normalized-albedo.json` and `NORMALIZATION.md`.

At each seed,243 close-view mask-transition neighborhoods were inspected using native-resolution luminance profiles. The neighborhood is±16px around a mask0.5 crossing. The strongest luminance-gradient location is an **edge-location proxy**; gradient second-moment spread is an **edge-profile-width proxy**, not a physical mortar-width or FWHM measurement. Results:

| Seed | Median gradient-peak shift |95th percentile shift | Median edge-profile-width ratio | Median local contrast ratio |
|---|---:|---:|---:|---:|
|0|0px|1px|1.0003|0.994|
|7|0px|1px|1.0008|0.975|

Local contrast is `(max-min)/mean` within each profile; the fifth-percentile contrast ratios are0.947/0.916. The native crop pairs visibly retain the mortar layout. These measurements do not prove every mortar edge is identical, and the RGB tones intentionally change.

Protected-mortar normal/roughness differences are at most1/255 encoded readback in close/grazing cases, within the declared2/255 tolerance. Distant source-only normal/roughness are exactly equal across the full image. Close/grazing interior differences are also at most1/255 here; changed albedo can change coherent brightness votes, so global channel identity is not claimed. Original normal/roughness input maps are unchanged.

## Motion and controls

64 matched camera poses:16 logarithmic approach/retreat poses and16 wall-pan poses for each seed0/7, baseline and combined captured at each pose. Actual motion GIFs show approach seed0 and pan seed7; all64 poses are recorded in `motion-settings.json`. Raw moving-image differences are not interpreted as flicker.

`world-stability.json` evaluates the actual production macro helper at16,384 **fixed world points**, under16 representative center-pixel footprints from the captured approach, for each seed. World positions and phase stay fixed; only derivatives change. The largest adjacent gain change is1/510, one quantum of the amplified RGBA8 probe. No `TIME` phase exists in the shader. This supports world-stationary, smooth footprint behavior for the sampled macro field. It does not establish universal temporal alias freedom or quantitatively isolate every source-texture mip transition; the matched motion previews remain the visual evidence for the whole material.

The complete current spatial shader with macro disabled and original packed albedo matches the frozen v0.7.0 framebuffer exactly. Enabled macro at strength0 also matches exactly (`controls.json`, zero byte difference). All9 fresh regression scripts pass, including opt-in eligibility/default-off UI smoke and existing smoke/GPU/coherent/structure/guard tests (`regressions.json`).

## Inspectable images

- `four-arms-30.0-seed0.png`: baseline / normalization / macro / both.
- `distant-wall-seed0.png`: distant overview pair.
- `distant-native-seed0.png`: full-resolution distant crop pair.
- `close-mortar-native-seed0.png`: full-resolution mortar crop pair.
- `pbr-grazing-seed0.png`: full PBR grazing comparison.
- `approach-seed0-motion.gif`, `pan-seed7-motion.gif`: actual matched motion.

Seed7 stills and the second-distance four-arm comparisons are also retained. Native crops use source pixels without resizing; overview panels are explicitly reduced to fit1280px width. Raw captures are task outputs in `/tmp/distant-brick-evaluation`, recreated by the scripts, rather than committed as hundreds of files.

## Reproduction

Run sequentially from the repository root:

```sh
/opt/homebrew/bin/godot --headless --path . --editor --import
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script tests/distant_brick_capture.gd
uv run --with pillow --with numpy --with scipy python tests/distant_brick_analyze.py
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 640x360 --script tests/distant_brick_capture.gd -- --motion
uv run --with pillow python tests/distant_brick_motion.py
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script tests/distant_brick_capture.gd -- --controls
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 640x360 --script tests/distant_brick_world_probe.gd
python3 tests/distant_brick_regressions.py
```
