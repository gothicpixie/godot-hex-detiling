# Atlas size and measured cost

**Retain the accepted 4×4 atlas.** None of the smaller candidates passes the complete predeclared noninferiority gate. The balanced 2×2 and 3×3 improve the color-repeat metrics, but each worsens intermediate seed 7 luminance correlation beyond the allowed five percentage points. No threshold was waived, and no further atlas-size trial was run.

The accepted reference is the complete shader/helper at 0f5322a, with both original 4×4 asset SHA256 hashes frozen in `fixtures/manifest.json`. Source changes only parameterize atlas tile count; default 4 is preserved. Fresh full-spatial controls show feature OFF matches v0.7.0 exactly, and explicit current N4 matches the full accepted 4×4 shader exactly, both 0 byte framebuffer differences (`controls.json`). The first control run exposed an unset-seed conversion bug in the test harness; its error log was preserved and only the corrected control was rerun. It was not a production failure.

## Quality outcome

The original distant quality criteria remain chromatic energy ratio ≤0.50, chromatic correlation ≤0.60, luminance correlation ≤0.75, rendered between-brick RGB variance ≥0.50 and mean brightness ±10%, all relative to the matched original v0.7.0. Additional noninferiority requires each candidate's chromatic energy/correlation and luminance-correlation ratios be ≤accepted 4×4 + 0.05 at both distances and seeds. Method and declarations are in `CRITERIA.md`; exact failures are in `quality-gate.json`.

| Candidate | Distant color energy, seeds 0/7 | Distant color correlation | Distant palette variance | Strict gate |
|---|---:|---:|---:|---|
| Accepted 4×4 |0.208 /0.191|0.433 /0.408|0.580 /0.593|Reference|
| Initial 2×2 |0.386 /0.351|0.586 /0.574|0.648 /0.659|FAIL: multiple degradations|
| Balanced 2×2 |0.127 /0.142|0.387 /0.352|0.566 /0.585|FAIL: one intermediate luminance case|
| Balanced 3×3 |0.146 /0.134|0.367 /0.353|0.580 /0.569|FAIL: one intermediate luminance case|

At intermediate seed 7, luminance correlation is 0.526 for 4×4, 0.673 for balanced 2×2 and 0.661 for balanced 3×3. The increases 0.147/0.135 exceed the 0.05 allowance. Balanced 2×2 also increases that case's luminance periodic-energy ratio from 0.480 to 0.680; this is not dismissed as denominator noise. Its chromatic energy improves from 0.431 to 0.350. The compact assets are therefore documented tradeoffs, not silently relabeled equal quality.

The one packing-only 2×2 retry balanced per-source brick palette means while preserving exact global palette counts, source masks/residuals and size. The final 3×3 trial used the same approved method. Source-aligned shader weights, grid, filters, maps and criteria were unchanged. All failed arms and raw metrics remain; initial 2×2 stills/metrics also have a separate `random-2x-failed/` archive. `metrics.json` includes every arm and absolute energy/variance values. Two distances × two seeds use known 240 px/60 px source-repeat displacements, not selected spectrum peaks.

Native protected RGB/alpha remain exact in preprocessing. The 3×3 candidate's rendered exact production alpha = 0 RGB differs by at most 1 byte; protected normal/roughness are exactly equal. Its 3072² import was verified at native resolution with 11 additional mips (12 levels total), 50,331,640 Image bytes and the same RenderingServer texture-accounting increment. Ordinary filtered boundary colors may change; native exact preservation is not a claim that all mixed mip pixels retain original RGB. Retained 4×4 motion/continuity evidence remains in `docs/individual_brick/VALIDATION.md`; current N4's complete-spatial equivalence control verifies backward compatibility rather than replaying a large identical suite.

## Texture memory, correctly scoped

Each arm was loaded alone in a fresh process, with the same small TextureRect render setup before loading. The RenderingServer `RENDERING_INFO_TEXTURE_MEM_USED` increment matched the theoretical uncompressed RGBA8 mip texel sum exactly:

| Texture | Native size | RGBA8 mip texel bytes | Engine-reported increment |
|---|---:|---:|---:|
| Original packed source |1024²|5,592,404 (5.33 MiB)|5,592,404|
| Accepted 4×4 |4096²|89,478,484 (85.33 MiB)|89,478,484|
|2×2 random/balanced |2048²|22,369,620 (21.33 MiB)|22,369,620|
|3×3 balanced |3072²|50,331,640 (48.00 MiB)|50,331,640|

This is isolated engine texture accounting, not a physical VRAM-residency measurement and not the entire material/project footprint. The source albedo/normal/roughness and render targets add further resources in a real scene. Fresh-process RSS observations are separately recorded in `memory-*.json` and `memory-summary.json`; RSS includes process memory/driver/staging behavior and is never labeled VRAM. No inference that a single bound sampler releases prior cached resources was used.

## Finite render-call experiment

Same final protocol for v0.7.0, accepted 4×4 and balanced 2×2 (explicitly the failed-gate compact tradeoff):1280×720; Brick 4; scale 2.5 m; normal strength 0.8; roughness enabled; seed 0; guard/coherent enabled; macroOFF. Close wall camera(.1, .1,2), distant full-coverage wall(.1, .1,32), sphere radius 6/height 12 camera(0,1,16). Wall 160×100 m. Same light/environment. GPUexclusive and asset-generation CPUquiet window.

Three rotated/reversed rounds;90 warmup+240 timed forced draws per arm. Yield once per four-draw batch outside timing, avoiding the known background process-frame scheduling floor. The timer surrounds only synchronous `RenderingServer.force_draw(false)`. All 27 arms emitted 240 post-draw callbacks and nonzero viewport drawcalls on every measured draw:6,480 actual measured draws total. GPU timer was zero throughout. Values are CPU render-call intervals with possible GPU queue backpressure, not FPS, whole-frame latency or isolated GPU durations. Batching is a methodological limitation; do not compare these values with historical differently scheduled tests.

| Scene | Arm | Median render-call ms | Round median range ms |
|---|---|---:|---:|
| close-wall | baseline | 0.920 | 0.920–0.921 |
| close-wall | four | 0.719 | 0.718–0.755 |
| close-wall | balanced | 0.748 | 0.703–0.749 |
| distant-wall | baseline | 0.742 | 0.732–0.746 |
| distant-wall | four | 1.019 | 1.016–1.031 |
| distant-wall | balanced | 1.020 | 1.018–1.021 |
| sphere | baseline | 1.003 | 0.995–1.073 |
| sphere | four | 0.849 | 0.840–0.945 |
| sphere | balanced | 0.703 | 0.698–0.737 |

The table reports median of three round medians and the full range, with no dropped rounds. Exact round means/medians/p95 values are retained in `benchmark.json`. Smaller storage did not improve wall render-call cost in this experiment; the compact atlas reduced the sphere's call interval. The 4×4 mode itself costs more than v0.7 in the distant wall while reducing the measured call interval in the other workloads. No universal performance benefit is claimed.
