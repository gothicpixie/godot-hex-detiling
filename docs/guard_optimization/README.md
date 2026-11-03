# Protect mortar sampling optimization

The mortar guard now shares its mask with albedo alpha and skips donor work when the source mask or distant-detail factor is exactly zero. The material mixture, two-to-eight-texel fade, coherent weights, normal reconstruction and optional donor detrending remain the same. The original repeating mortar layout and its limitations remain; this reduces sampling work rather than synthesizing new brick structure.

## Packed mask and compatibility

The demo's packed Brick 4 copy preserves the original decoded RGB and puts the matching linear interior mask in alpha. The original JPEG and mask remain unchanged. Reference and donor RGBA samples supply both color and mask, eliminating four separate mask fetches per projection. With roughness enabled and detrending off, worst-case triplanar reads fall from **48 to 36**. When all projections return the original material, the packed path needs **nine** reads: albedo, normal and roughness on each axis. Optional detrending adds up to twelve reads on donor paths. These source-level counts are not timing estimates.

The generic shader adds `structure_guard_in_albedo_alpha=false`; existing separate-mask materials and the missing-map black fallback remain supported. Packed alpha must match the albedo's dimensions, UVs, filtering and mip behavior. RGB keeps source-color decoding while alpha stays linear. Use lossless import, mipmaps, `process/fix_alpha_border=false` and `process/premult_alpha=false`; border repair and premultiplication would change protected mortar RGB. Packing replaces the original alpha channel and is suitable for this opaque material only; preserve opacity in another channel or use the separate-mask path for materials that need their original alpha. See [packing recipe, source hashes and import settings](PACKING.md).

The demo selects packed albedo only when Brick 4, Preserve pattern, Protect mortar and detiling are active. Turning protection, structure or detiling off restores the original albedo and clears the packed flag and mask. Source changes retain the Protect mortar preference and previous blend choice. There is no additional texture-packing UI control.

An exact zero reference mask or detail factor returns original color, normalized source normal slope and optional roughness before donor sampling. Partial mask/fade values retain every donor normal sample because normal guidance can change all coherent weights before masking. Rejected donor weight still returns to the original source without renormalizing survivors. All projection gradients are computed before data-dependent returns, and all affected samples use explicit gradients.

## Measured render-call cost

Fresh frozen v0.6.0 and optimized shaders were measured on Apple M5 / Godot 4.7.2 Compatibility at 1280 × 720. Each arm has three rounds, 180 warmups and 600 measured synchronous `RenderingServer.force_draw(false)` calls per round. Values below are the median of the three round medians, with the range of round medians in parentheses.

| Scene | Frozen v0.6.0, ms | Packed + early return, ms | Change |
| --- | ---: | ---: | ---: |
| Terrain | 4.421 (4.421–4.735) | 2.062 (2.058–3.828) | −53.4% |
| Close wall | 4.111 (4.025–4.164) | 3.523 (3.433–3.541) | −14.3% |
| Distant wall | 1.007 (1.003–1.266) | 0.874 (0.853–0.971) | −13.2% |

These are **CPU wall times around a synchronous render call**, excluding the awaited frame scheduling interval. They can include driver overhead and GPU queue backpressure. They are **not GPU timings, whole-frame latency or FPS measurements**; engine GPU timer samples remained zero. Terrain results varied substantially between rounds, and the distant wall has low coverage and can be limited by submission overhead. Both changes together had the lowest median in each tested scene, so both are retained. This single-device result does not establish a general speedup.

The [complete four-arm table](benchmark-table.md) includes packing alone and early return alone; [raw rounds](benchmark.json), [summary](benchmark-summary.json), and [protocol/reproduction](VALIDATION.md#benchmark-protocol) preserve the evidence. The earlier v0.6.0 whole-frame benchmark is a different metric and is not used for these percentages. Interrupted CPU-overlap and background-scheduling logs are superseded diagnostics, not final results.

## Matched output and motion

CPU packing checks preserve all decoded source RGB and mask bytes. Twelve GPU import probes cover LOD 0, 1, 2, 3, 5 and 10 with isotropic and 16:1 gradients; all report zero observed RGB/alpha error at the amplified RGBA8 probe resolution. Full material checks cover guard off/on, seeds 0/7, normal/roughness settings, detrending and frontal/grazing/distant views. Independent helper checks also cover both packed and separate-mask paths around the fade cutoff. Maximum observed output difference is one RGBA8 byte per channel in the sampled comparisons; this does not establish bitwise floating-point identity.

Actual matched camera motion compares the frozen and optimized shaders at the same camera poses: wall pan, approach/retreat, grazing wall and terrain, each with seeds 0 and 7. The strengthened approach path spans 1.5–120 m and crosses the two-to-eight-texel fade. The measured temporal increment mismatch, `(new[t]-new[t-1])-(old[t]-old[t-1])`, is at most one RGBA8 byte per channel in these sequences. It measures disagreement between implementations, not the amount of motion or inherent aliasing. These captures do not establish universal alias-free behavior.

View the side-by-side motion: [approach/retreat, seed 0](approach-retreat-seed0-motion.gif), [seed 7](approach-retreat-seed7-motion.gif), [terrain, seed 0](terrain-seed0-motion.gif), [seed 7](terrain-seed7-motion.gif). The [validation record](VALIDATION.md), [per-frame motion analysis](motion-summary.json), and lossless [worst terrain frame, frozen](terrain-seed0-worst-old.png) / [optimized](terrain-seed0-worst-new.png) give the settings and bounded evidence. GIF palettes are for viewing; quantitative comparisons use the original lossless readbacks.
