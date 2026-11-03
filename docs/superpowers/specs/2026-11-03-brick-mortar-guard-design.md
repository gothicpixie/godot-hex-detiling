# Brick mortar guard

Add an independent, disabled-by-default `structure_guard_enabled` option with a repeating linear-data `structure_guard_map`. Zero protects the original source material; one permits donor variation. A missing map defaults to black. The guard is active only with both structure preservation and detiling enabled, and uses coherent material weights regardless of the blend selector.

For each triplanar projection, retain the original source color, normal slope and roughness at `st`. Reuse the three structured donor positions and coherent weights `W`. Sample the guard at the source (`M0`) and donor positions (`Mi`), multiply donor weights by `M0 * Mi`, and assign all remaining weight to the original source. Never renormalize the surviving donors. Apply the same four weights to all material channels. Original protected color is not detrended; optional detrending still applies to donor color.

A conservative source-specific mask protects the irregular scanned mortar and transitions smoothly to safe brick interiors. The shader also reduces donor contribution when the pixel footprint grows, reverting to source sampling before mip filtering can average protected mortar into permissible regions. Donor weight uses `1-smoothstep(2,8,footprint)`, with footprint the larger derivative length in mask-texel space. This heuristic cutoff and its visual tradeoff must be checked with GPU fixtures and matched captures.

The demo binds the Brick 4 mask only for that source. A separate Protect mortar checkbox is eligible only while Preserve pattern is enabled on Brick 4; its preference persists while the shader parameter and map are cleared on unsupported sources. Its tooltip states that protection uses common coherent weights. Existing structure presets and default shader behavior remain unchanged.

The original mortar pattern and its repetition remain. Interior variation is restricted and fades with distance; this is not automatic segmentation or new brick synthesis. The active option adds four mask reads plus source albedo/normal and optional roughness reads per projection. No performance or artifact-free claim is made without evidence.
