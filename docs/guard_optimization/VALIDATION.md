# Protect mortar optimization validation

Reference: immutable full v0.6.0 shader **and matching helper** from `3b9216b`. The existing pre-guard contracts use a separate immutable shader/helper pair from `6c9cabf`. All fixtures are MIT-licensed repository code. No test depends on `/tmp` baseline source. Motion raw images are temporary outputs, recreated by the test.

Environment: `/opt/homebrew/bin/godot`, Godot 4.7.2 official `ed1daf0bf001b61586d9930840f2f1394092c079`, Apple M5, Compatibility OpenGL 4.1 Metal 90.5. GPU processes run sequentially. UI hidden, fixed light/environment, no live input or animation. Root framebuffer is RGBA8; this Compatibility path does not provide floating canvas readback. The tests declare a maximum **2/255 per channel** framebuffer tolerance before capture. Independent helper normals are mapped from [-1,1] to [0,1]. These readback results do not establish bitwise floating-point equality.

## Equivalence

`import-gpu.json` checks imported source-color RGB versus the original JPEG and packed linear alpha versus the original mask. Explicit texture gradients exercise LOD 0,1,2,3,5,10 isotropically and at 16:1 gradients. Error is amplified by32 before RGBA8 readback, giving 1/(255*32) resolution. All12 cases report zero observed error. CPU pixel validation and importer settings are recorded in `packed-albedo.json`.

`equivalence.json`:48 full spatial shader settings and384 matched motion frame pairs. The spatial matrix covers guard off/on, seeds0/7, normal/roughness maps off/on, detrend0/0.6, frontal/grazing/distant cameras. All pass; maximum observed RGB difference1/255.

`channels.json`:144 comparisons of the real production coherent helper against the frozen helper, independently displaying color, normal and roughness. Packed and separate-mask fallback paths, seeds0/7, map/detrend combinations, 16:1 gradients and mask footprints0.25,2,3.5,7.99,8,12 texels all pass; maximum observed channel difference1/255. The exact8-texel cutoff and just-below cutoff are distinct cases.

## Matched camera motion

Each of wall pan, approach/retreat, grazing wall and terrain has48 camera poses per seed0/7. Every old/new pair uses the same camera and settings, captured after deterministic rendering, rather than live asynchronous recordings. The approach path was strengthened to1.5..120m at x=y=0.1m using `z=1.5*pow(80,sin(pi*t))` to resolve the2..8texel fade across several captured frames; `approach-equivalence.json` records that replacement capture. `approach-footprints.json` instruments the actual dominant wall projection derivatives at the visible center on the captured logarithmic trajectory: frames0/1 at1.5/2.01m are below2texels, frames2–5 at2.69/3.59/4.77/6.31m are within2–8texels, frame6 at8.30m and frame23 at119.71m are above8. This confirms both fade thresholds are covered, rather than inferring footprint from camera distance alone. The terrain sequence exercises all three projections.

`motion-summary.json` reports per-frame maximum/mean/RMSE, outlier frames, and the temporal residual **(new[t]-new[t-1]) - (old[t]-old[t-1])**. Raw motion differences are never presented as flicker measurements. GIFs show actual camera motion with frozen and optimized views side-by-side. Lossless worst-frame old/new stills are retained per trajectory/seed. These observations support equivalence on the sampled motions; they do not establish universal alias-free behavior.

## Reproduction

Run from the repository root (one GPU process at a time):

```sh
/opt/homebrew/bin/godot --headless --path . --editor --import
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --resolution 640x360 --script tests/guard_import_probe.gd
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --resolution 640x360 --script tests/guard_channel_probe.gd
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --resolution 640x360 --script tests/guard_optimization.gd
uv run --with pillow --with numpy python tests/guard_optimization_media.py
/opt/homebrew/bin/godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script tests/guard_optimization.gd -- --bench
```

## Benchmark protocol

Four arms derive from production: frozen v0.6.0, packed-only (remove exactly one marked early-return block), early-only (original RGB+separate mask), both. The harness asserts the packed-only transform removed the exact condition and changed the source. No alternate donor algorithm is copied into the test. Three rounds per scene,180 warmup and600 measured frames per arm, reversed/rotated order. Terrain, close wall and distant wall use the same camera/material per arm. Final results are synchronous `RenderingServer.force_draw(false)` call intervals in milliseconds, measured immediately before/after the call. The timer excludes `await process_frame` and therefore excludes the observed background frame-wait floor. These CPU render-call intervals can include GPU queue backpressure; they are neither isolated GPU time nor whole-frame latency. The GPU timer reported zero. Each arm records the actual frame-post-draw callback count and viewport draw calls.

An initial run overlapped CPU media generation and was interrupted. A second scheduling diagnostic exposed that `process_frame` can continue while the macOS background render loop stops; adding `frame_post_draw` alone then stalled. Those logs are explicitly diagnostic. A further diagnostic showed that timing across the awaited frame still included macOS scheduling. The final run disables the automatic render loop, calls `RenderingServer.force_draw(false)` once per iteration, and times only that synchronous call. Only `benchmark.json` / `benchmark.log` are used for conclusions. CPU/OS scheduling within the call remains a limitation; round ranges are reported.

Benchmark material: Brick4, structured coherent blend, mortar guard enabled, texture scale2.5m, normal strength0.8, roughness map enabled, blend contrast0.65, detrend0, seed0. Terrain camera(9,6,10), close-wall camera(1,1,8), distant-wall camera(1,1,120), all looking at origin. Wall size14×8×1; distant wall has low screen coverage and can be submission-bound. Default52° vertical FOV. No comparison uses historical machine timings.

Final timing table (median of the three round medians, with the full round range; no dropped rounds):

| Scene | Arm | Median ms | Round range ms | Change vs frozen |
|---|---|---:|---:|---:|
|terrain|frozen|4.421|4.421–4.735|+0.0%|
|terrain|pack|3.854|3.715–4.632|-12.8%|
|terrain|early|2.592|2.558–3.691|-41.4%|
|terrain|both|2.062|2.058–3.828|-53.4%|
|close-wall|frozen|4.111|4.025–4.164|+0.0%|
|close-wall|pack|3.993|3.854–4.154|-2.9%|
|close-wall|early|3.832|3.742–3.997|-6.8%|
|close-wall|both|3.523|3.433–3.541|-14.3%|
|distant|frozen|1.007|1.003–1.266|+0.0%|
|distant|pack|0.988|0.938–1.441|-1.9%|
|distant|early|0.886|0.866–0.911|-12.0%|
|distant|both|0.874|0.853–0.971|-13.2%|

Both optimizations had the lowest median in each sampled workload. Packed-only effects are small and overlapping in close/distant wall cases. Terrain round variation is substantial, so the measured53.4% terrain reduction describes this draw-call experiment, not a guaranteed application frame-rate gain. Close-wall and distant-wall draw-call median reductions were14.3% and13.2%.

Every final arm emitted exactly600 `frame_post_draw` callbacks during600 measured forced draws, and the viewport reported1 draw call in the rendered frame. Thus the measured loop did render the scene, rather than timing idle frames. There were21,600 measured draws total. All36 arms and all three rounds are retained. `benchmark-paired.json` additionally pairs both/frozen medians within each round: mean paired reductions were42.0% terrain,14.7% close wall,16.5% distant; median paired reductions were53.4%,14.7%,15.3%. The main table instead divides the median of each arm's round medians by the corresponding frozen median; these are different aggregations and are labeled separately.

Final refreshed motion analysis:384 matched frames, maximum framebuffer difference1/255 and maximum temporal-increment residual1/255; no frame exceeds the declared2/255 frame tolerance. The verified approach replacement contributes96 of those384 final frames. The four GIFs depict approach/retreat and terrain for both seeds; wall/grazing sequences retain metrics and worst lossless stills.

## Existing regression contracts

`regressions.json` records successful smoke, GPU, coherent, structure smoke/probe, guard UI smoke/probe and full historical spatial baseline tests. The guard UI smoke now checks the packed albedo and flag, detile-off restoration to original RGB, and detile-on restoration to packed.

The existing guard probe initially failed its weight-visualization case at mask0 because it instrumented only the final color assignment; the valid source-only early return bypassed that diagnostic assignment. The harness now instruments that actual exit as its known one-hot anchor mixture as well. Only the probe was rerun, and all checks passed. Actual color/normal/roughness preservation had already passed. No production source changed during validation.
