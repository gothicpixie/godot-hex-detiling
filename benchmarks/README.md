# Benchmark: demo scene

This is a reproducible **whole-scene frame pacing measurement**, not an isolated GPU shader benchmark. It cannot determine the shader's GPU cost on its own. The renderer returned no GPU timing samples on this machine; do not interpret the numbers below as GPU time.

## Result recorded November 2, 2026

- MacBook Pro, Apple M5, 24 GB unified memory, macOS 26.6.2; Godot 4.7.2 stable.
- Compatibility renderer, OpenGL 4.1 through Metal; requested 1280 × 720 window; procedural terrain and light, UI hidden, two 2K textures with mipmaps; rotation and roughness sampling off, neutral blend contrast. The window may be subject to OS display scaling.
- V-sync disabled by command line and FPS uncapped as requested. Driver or OS behavior can still affect pacing.
- Three alternating rounds per mode, 180 warm-up frames and 600 measured frames per round. The script records elapsed time between process-frame callbacks; it includes engine, CPU scheduling, presentation behavior, and asynchronous rendering. It is not a GPU timer.

| Mode | Median frame interval by round (ms) | Mean interval by round (ms) |
| --- | --- | --- |
| Periodic | 0.866, 0.864, 0.864 | 0.998, 0.966, 1.067 |
| Detiled | 2.362, 2.366, 2.361 | 2.436, 2.467, 2.440 |

The measured frame intervals were longer in the detiled mode for this scene, but these numbers do not establish an isolated GPU cost or a generally applicable speed ratio. Different screen coverage, textures, GPUs, drivers, and renderers can change the result substantially. A Forward+ trial appeared refresh-limited at roughly 8.3 ms and also produced zero GPU samples; it was not used for a comparison. Profile GPU time with a supported hardware profiler in your target scene before deciding whether to ship the effect. Raw Compatibility output is in [apple-m5-compatibility.txt](apple-m5-compatibility.txt).

## Reproduce

Import the project first, then run on a graphics display:

```sh
godot --path . --resolution 1280x720 --disable-vsync --max-fps 0 --script res://benchmarks/benchmark.gd
```

Do not use headless mode for this test. The script prints each round's median, mean, 95th-percentile frame interval, and any nonzero viewport GPU timing samples. Run several times and keep the machine's power, display, renderer, scene coverage and background workload consistent. Results may be noisy or refresh-limited even with V-sync disabled.

## Paper-inspired mode comparison

On the same machine and Compatibility renderer, a second run used the current terrain scene at 1280 × 720, rotation 0.65, blend contrast 0.65, and roughness-map sampling on. It alternated periodic, shared-weight detiling, and paper-inspired detiling twice; each round used 180 warm-up and 600 measured frames.

| Mode | Median frame intervals by round (ms) |
| --- | --- |
| Periodic | 1.064, 1.065 |
| Shared weights | 3.314, 3.316 |
| Paper-inspired weights | 3.317, 3.352 |

These are process-frame intervals, **not GPU times**. GPU timing again returned zero samples; the close shared/paper numbers cannot establish an isolated GPU cost or a general performance relationship. Results vary with hardware and scene. Raw output: [apple-m5-paper-compare.txt](apple-m5-paper-compare.txt).

Reproduce on a graphics display after importing:

```sh
godot --path . --resolution 1280x720 --disable-vsync --max-fps 0 --script res://benchmarks/paper_compare.gd
```

## Optional coherent-mode comparison — November 3, 2026

The final run used Godot 4.7.2 Compatibility / OpenGL 4.1 through Metal on Apple M5, a requested 1280 × 720 window, V-sync disabled, and uncapped FPS. The default rock terrain retained its lights and material, with UI hidden, rotation 0.65, blend contrast 0.65, and roughness-map sampling on. Coherent filtering remained enabled and detrending disabled. Nine alternating rounds measured shared, paper-inspired, and coherent modes three times each, with 180 warm-up frames and 600 measured process-frame intervals per round. No other GPU task ran concurrently.

| Mode | Median frame intervals by round (ms) | 95th-percentile intervals by round (ms) |
| --- | --- | --- |
| Shared weights | 3.276, 3.295, 3.281 | 3.658, 3.636, 3.672 |
| Paper-inspired | 3.328, 3.343, 3.325 | 3.689, 3.774, 3.679 |
| Coherent material | 3.089, 3.100, 3.092 | 3.449, 3.463, 3.479 |

Every round returned **zero GPU timing samples**. These are whole-scene process-frame intervals, including CPU scheduling and presentation behavior, not isolated shader GPU times. Coherent mode had shorter recorded intervals in this run, but these measurements do not establish a general GPU speedup or a performance ordering on other hardware. At equal roughness/detrending settings, coherent mode adds no source-level texture reads; it changes arithmetic and sampling organization, whose cost depends on compiler and hardware.

The [raw final output](apple-m5-coherent-compare.txt) includes the exact invocation, date, all means, and result JSON. Reproduce on a graphics display after importing:

```sh
godot --path . --rendering-method gl_compatibility --resolution 1280x720 --disable-vsync --max-fps 0 --script res://benchmarks/coherent_compare.gd
```

See [method and bounded quality checks](../docs/coherent/README.md) before interpreting this as a visual-quality comparison.

## Brick mortar guard comparison — November 3, 2026

Apple M5, Godot 4.7.2 Compatibility / OpenGL 4.1 through Metal, requested 1280 × 720, V-sync disabled, UI hidden, matched brick terrain, roughness enabled and detrending off. Three alternating rounds per mode used 60 warm-up and 180 measured process-frame intervals. Existing structured mode explicitly disabled the new guard; active guarding retained common coherent blending.

| Mode | Median whole-frame intervals by round (ms) | Mean of round medians (ms) |
| --- | --- | --- |
| Existing structured | 3.432, 3.421, 3.452 | 3.435 |
| Mortar guarded | 5.607, 5.681, 5.590 | 5.626 |

The mean of round medians increased about 63.8% in this run. These are whole-frame intervals including CPU scheduling and presentation overhead, **not isolated GPU timings**; Godot returned zero GPU timer samples. This single-device comparison does not establish a general speed ratio. Active full PBR guarding adds 21 source-level reads (27 → 48 with detrending off); its distant fallback reduces donor contribution while retaining those reads.

[Raw output](../docs/brick_guard/benchmark.log), [matched visual evidence and tradeoffs](../docs/brick_guard/README.md), and [complete validation](../docs/brick_guard/VALIDATION.md) accompany the result. Reproduce after importing, on a graphics display with other GPU tasks stopped:

```sh
godot --path . --rendering-method gl_compatibility --resolution 1280x720 --disable-vsync --max-fps 0 --script res://benchmarks/brick_guard_compare.gd
```


## Packed guard and exact source fallback — November 3, 2026

This comparison reruns frozen v0.6.0 (`3b9216b`, shader and matching helper), packing alone, exact source-only early return alone, and both. It uses a new metric: **CPU wall time immediately around `RenderingServer.force_draw(false)`**, excluding awaited frame scheduling. Driver overhead and GPU queue backpressure can contribute. This is not isolated GPU time, whole-frame latency or FPS; GPU timer samples remained zero. Do not compare these values or percentages with the historical process-frame measurements above.

Apple M5, Godot 4.7.2 Compatibility, 1280 × 720, three rounds per scene/arm, 180 warmup and 600 measured calls per round. Each arm records 600 actual post-draw callbacks and one viewport draw call. Values are median of round medians; parentheses show their range.

| Scene | Frozen, ms | Packing only, ms | Early return only, ms | Both, ms |
| --- | ---: | ---: | ---: | ---: |
| Terrain | 4.421 (4.421–4.735) | 3.854 (3.715–4.632) | 2.592 (2.558–3.691) | 2.062 (2.058–3.828) |
| Close wall | 4.111 (4.025–4.164) | 3.993 (3.854–4.154) | 3.832 (3.742–3.997) | 3.523 (3.433–3.541) |
| Distant wall | 1.007 (1.003–1.266) | 0.988 (0.938–1.441) | 0.886 (0.866–0.911) | 0.874 (0.853–0.971) |

Both changes had the lowest median in each tested scene (53.4%, 14.3%, 13.2% shorter than the fresh frozen baseline respectively), so both are retained. Terrain round variation is large; distant geometry has low coverage and can be submission-bound. This is one device, renderer and workload, not a general GPU speedup. Initial interrupted CPU-overlap and background-scheduling logs are superseded diagnostics; only the final `benchmark.json` / `benchmark.log` support the table.

See [protocol, exact settings and reproduction](../docs/guard_optimization/VALIDATION.md#benchmark-protocol), [raw rounds](../docs/guard_optimization/benchmark.json), [full table](../docs/guard_optimization/benchmark-table.md), and [matched output and motion](../docs/guard_optimization/README.md). Reproduce after import, with other GPU/CPU media jobs stopped:

```sh
godot --path . --always-on-top --disable-vsync --disable-render-loop --resolution 1280x720 --script res://tests/guard_optimization.gd -- --bench
```
