# Individual-brick appearance: bounded improvement with preserved joint layout

The final squared-weight stochastic mode passes the predeclared distant source-color and palette-retention criteria for both evaluated seeds. Colored patch repetition is substantially weaker than the original and previous macro experiment. The mortar/joint layout and fine weathering template still repeat; this is not a universally aperiodic or alias-free material. Some bricks retain darker perimeter rims, and individual interior feature contrast can change considerably.

All results below use the final `W *= W;` followed by normalized shared barycentric weights. The initial linear-weight result is explicitly superseded: it reduced repetition but retained only47.1%/48.2% of distant between-brick RGB variance, failing the declared50% floor. Its full shader/helper, metrics, stills and completed motion settings are preserved in `fixtures/linear-weights.*` and `linear-weights/`. Exactly one root-approved quality adjustment squared the weights; assets, offsets, filters, thresholds and criteria were unchanged.

## Controlled comparisons

Four arms: original guarded v0.7.0 from6732aff6; frozen previous normalized+macro experiment fromd0fcb5e; direct4×4atlas; primary stochastic atlas. Each frozen shader includes its matching frozen helper. Both new arms have macro OFF and use original periodic normal/roughness sampling aligned with the baked RGB detail. This intentionally replaces the old near-interior donor mixture; those interior material channels are not claimed identical.

16 orthographic unlit images cover2 distances×2 seed cases×4 arms. Height7.5m/30m, source scale2.5m,1280×720, wall160×100m. Camera projection measures exact source-repeat shifts240px/60px. The distant view spans3 complete atlas periods vertically. Seed cases are atlas0/hash0 and atlas7/hash7. The demo defaults to atlas0; the alternate atlas is bound explicitly by the evaluation, independently of continuous runtime hash-seed controls.

GPU: `/opt/homebrew/bin/godot`, Godot4.7.2 official `ed1daf0bf`, AppleM5, Compatibility OpenGL4.1/Metal90.5. UI hidden; deterministic matched camera/light/material settings; RGBA8 readback. Automatic rendering is disabled and each capture explicitly draws twice. No benchmark or application frame-rate claim was made.

## Repetition and palette

Analysis converts RGB to linear light and uses luminance plus opponent channelsR-G/B-G. Gaussian sigma=source-period/16 suppresses the intended finer brick lattice. Full-source correlation is Pearson correlation at the known source displacement, averaged arithmetically over x/y and, for color, the two opponent channels. Raw phase-locked spectral energy uses source harmonics1..6, excludes DC and the intended finer brick pitch, and is divided by mean-luminance squared. Added variance or darkening therefore does not count as removal of the periodic numerator. Raw energies, every axis/channel, mean brightness and total variance are retained in `metrics.json`.

Distant ratios versus the corresponding original baseline:

| Arm | Chromatic periodic energy, seed0/7 | Chromatic correlation, seed0/7 | Luminance correlation, seed0/7 | Between-brick RGB variance, seed0/7 |
|---|---:|---:|---:|---:|
| Previous normalized+macro |0.707 /0.702|0.891 /0.898|0.847 /0.861|1.052 /1.052|
| Direct atlas |0.222 /0.188|0.290 /0.256|0.427 /0.335|0.874 /0.870|
| **Final stochastic** |**0.208 /0.191**|**0.433 /0.408**|**0.569 /0.502**|**0.580 /0.593**|

The primary mode reduces measured chromatic periodic energy79.2%/80.9%, source-size color correlation56.7%/59.2%, and luminance correlation43.1%/49.8%. All pass the original≥50%/≥40%/≥25% targets. Actual GPU per-brick RGB variance retains58.0%/59.3%, above the50% floor; this guard measures the blended output, not just the source atlas. Region means use known orthographic projection and native connected-region labels, exact-white interior cores, and at least4 captured core pixels per region.

Intermediate primary color correlation ratios0.516/0.467 and RGB-variance ratios1.512/1.568 are also reported. The old coherent donor mixture has lower interior contrast there; near appearance is intentionally different. Mean luminance ratios remain0.980–0.985 across both primary distances/seeds. Static gradients are well below the coarse-fade threshold, so these results are not achieved by fading the view to a flat global mean.

The direct atlas alone is still periodic every4source repeats/10m. At that full atlas displacement, distant mean chromatic correlation is0.99060/0.99074, almost the original0.99655. Final stochastic correlation at the same displacement is0.44661/0.40728. Thus the primary result breaks the tested fixed atlas-period pattern rather than merely making the repeating texture larger. Residual mortar geometry and fine source features remain correlated; no unbounded nonrepetition claim follows.

Native independent audit (`asset-audit.json`): all16,777,216 alpha pixels match their repeated source, and all6,801,920 protected RGB pixels match exactly per atlas. Across1,328 proper brick cores, native RGB palette variance is1.050/1.052×source; median normalized fine-detail highpass contrast is1.0038/1.0037×source. Preprocessing preserves source coordinates without warping/resampling. Tiny highlight gamut adjustments and the finite variant-bank design are disclosed in `PREPROCESSING.md` and asset provenance.

## Mortar, adverse profiles and PBR

The GPU classifier renders a binary result from the **actual production packed alpha comparison `textureGrad(...).a == 0.0`**. It does not infer exact protection from a near-black screenshot of the separate mask. That earlier near-black classifier included nonzero-alpha pixels and was corrected; its initial diagnostics remain in the superseded linear evidence.

At351,386 close and158,515 grazing canonical protected pixels per seed, rendered shaded RGB differs by at most1/255; normal and roughness readbacks are exactly equal. At distance no pixel has exactly-zero filtered alpha, so protected-pixel statistics are explicitly unavailable there; normal/roughness are exactly equal over the entire distant image. See `protected-rendered-rgb.json` and `metrics.json`. Native exact RGB preservation is not used as a substitute for these rendered measurements.

243 native close mask-transition neighborhoods per seed measure gradient-location and gradient-spread **proxies**, not physical mortar width. Median gradient-peak displacement is0px; median edge-profile-width ratios1.0196/1.0007 and median local contrast ratios1.005/1.012 pass their declared limits. Tails matter:95th-percentile peak displacement is16.9px and fifth-percentile local contrast ratios0.738/0.789.

Four adverse native crop pairs are retained as `edge-tail-{peak-shift,contrast-loss}-seed{0,7}.png`, with exact coordinates in `edge-tail-review.json`. Yellow marks the33px profile, cyan its mask0.5 crossing, magenta the strongest gradient. Worst shifts30px/26px switch between an interior chip/corner feature and an edge; the visible joint lines remain aligned. Worst local contrast ratios0.476/0.460 are real feature/tone changes, not evidence that every edge contrast is unchanged. Independent visual review found no doubled joint or joint blur in these crops, but darker preserved perimeter rims can remain visible on strongly recolored bricks. Inspect the images rather than treating median proxies as an aesthetic guarantee.

The new route uses periodic original normal/roughness maps to align fine detail with the baked atlas. Near-interior differences versus the old coherent donor mixture are intentional and visible. Protected and distant equality are the bounded preservation claims.

## Motion, continuity and off controls

64 final matched camera poses:16 logarithmic approach/retreat poses and16 wall-pan poses for each seed. Baseline and final primary camera positions match exactly (`motion-pair-audit.json`). Approach reaches roughly300m to include the coarse-filter transition. Actual motion GIFs show approach seed0 and pan seed7. Raw differences between moving images are never called flicker measurements.

The actual production `brick_individual_color` helper is independently queried at16,384 points per case. Across three real triangle-edge families at source-UV offsets±0.000001, maximum observed linear RGB change is0.0009804, below the declared2/255 tolerance. Fixed-world footprint probes±0.01% around native mip levels and both coarse-fade endpoints show zero observed RGB difference at1/(255×32) readback resolution. Actual GPU detail values at source footprints0.05/0.15/0.35 are1.0/0.706/0.0, proving the full fade was exercised. No TIME/camera phase drives the field. These are bounded continuity checks, not proof of universal temporal alias freedom or large-world floating-point stability (`continuity.json`).

Individual mode OFF matches the full frozen v0.7.0 framebuffer exactly. Individual mode OFF with the prior normalized+macro experiment also matches frozen d0fcb5e exactly:0byte differences in both controls. All10 fresh smoke/GPU/coherent/structure/guard/experiment regression scripts pass. Default-off and unsupported-material behavior remain intact.

## Visual evidence and reproduction

- `four-arms-native-30.0-seed0.png`: all four arms at native pixel scale.
- `distant-wall-seed0.png`: overview, reduced to fit1280px total width.
- `distant-native-seed0.png`, `close-mortar-native-seed0.png`: native before/after pairs.
- `pbr-grazing-seed0.png`: full PBR grazing comparison.
- Four `edge-tail-*.png` pairs expose adverse profiles.
- `approach-seed0-motion.gif`, `pan-seed7-motion.gif`: actual matched motion.

Seed7 and intermediate stills are retained. Raw captures are reproducible task outputs under `/tmp/individual-brick-evaluation`; initial linear raw captures are separately preserved under `/tmp/individual-brick-linear-evaluation`. Source fixtures and numerical evidence do not depend on temporary baseline shader files.

Run from the repository root against the final squared-weight source, sequentially for GPU commands:

```sh
/opt/homebrew/bin/godot --headless --path . --editor --import
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script tests/individual_brick_capture.gd
uv run --with pillow --with numpy --with scipy python tests/individual_brick_analyze.py
uv run --with pillow --with numpy --with scipy python tests/individual_brick_asset_probe.py
uv run --with pillow --with numpy python tests/individual_brick_edge_review.py
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 640x360 --script tests/individual_brick_capture.gd -- --motion
uv run --with pillow python tests/individual_brick_motion.py
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 640x360 --script tests/individual_brick_continuity.gd
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script tests/individual_brick_capture.gd -- --controls
python3 tests/individual_brick_regressions.py
```

Final development reruns captured only the primary arm after the approved one-line adjustment; original/previous/direct captures were reused at identical settings. The commands above regenerate every final arm from scratch. Each 4096² atlas contains about 85.3 MiB of theoretical uncompressed RGBA8 texel storage including mipmaps, versus about 5.3 MiB for the original 1024² packed texture. This is not a measured allocation, VRAM or process-memory result. Binding one atlas does not establish how many resources remain resident; two such textures contain about 170.7 MiB of uncompressed texels. Default-off opt-in status is appropriate; no performance benefit is claimed.
