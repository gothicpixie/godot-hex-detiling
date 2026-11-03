# Benchmark: demo scene

This is a reproducible **whole-scene frame pacing measurement**, not an isolated GPU shader benchmark. It cannot determine the shader's GPU cost on its own. The renderer returned no GPU timing samples on this machine; do not interpret the numbers below as GPU time.

## Result recorded November 2, 2026

- MacBook Pro, Apple M5, 24 GB unified memory, macOS 26.6.2; Godot 4.7.2 stable.
- Compatibility renderer, OpenGL 4.1 through Metal; requested 1280 × 720 window; demo wall and light, UI hidden, two 2K textures with mipmaps. The window may be subject to OS display scaling.
- V-sync disabled by command line and FPS uncapped as requested. Driver or OS behavior can still affect pacing.
- Three alternating rounds per mode, 180 warm-up frames and 600 measured frames per round. The script records elapsed time between process-frame callbacks; it includes engine, CPU scheduling, presentation behavior, and asynchronous rendering. It is not a GPU timer.

| Mode | Median frame interval by round (ms) | Mean interval by round (ms) |
| --- | --- | --- |
| Periodic | 0.594, 0.610, 0.359 | 0.779, 0.995, 0.448 |
| Detiled | 0.665, 0.639, 0.632 | 0.847, 0.733, 0.726 |

The variation is large relative to the observed difference. These measurements do not establish a reliable speed ratio or isolated cost. Different screen coverage, textures, GPUs, drivers, and renderers can change the result substantially. A Forward+ trial appeared refresh-limited at roughly 8.3 ms and also produced zero GPU samples; it was not used for a comparison. Profile GPU time with a supported hardware profiler in your target scene before deciding whether to ship the effect. Raw Compatibility output is in [apple-m5-compatibility.txt](apple-m5-compatibility.txt).

## Reproduce

Import the project first, then run on a graphics display:

```sh
godot --path . --resolution 1280x720 --disable-vsync --max-fps 0 --script res://benchmarks/benchmark.gd
```

Do not use headless mode for this test. The script prints each round's median, mean, 95th-percentile frame interval, and any nonzero viewport GPU timing samples. Run several times and keep the machine's power, display, renderer, scene coverage and background workload consistent. Results may be noisy or refresh-limited even with V-sync disabled.
