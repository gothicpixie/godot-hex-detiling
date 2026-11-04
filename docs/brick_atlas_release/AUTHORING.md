# Preparing a source-aligned brick palette atlas

This mode needs a prepared opaque material, not just an arbitrary brick photograph. Supply aligned, repeating albedo, OpenGL normal and optional roughness maps, plus a source-specific mortar/interior mask. Black protects original RGB; white permits recoloring; a feathered band connects them. Inspect actual irregular brick boundaries, including wrapped source edges. Matching displacement can help author the mask, but thresholds and exclusions are source-specific and require review. Connected regions must not merge neighboring bricks or split one physical face into different palette identities.

The preprocessing identifies eligible regions, estimates each brick's broad RGB base, and reassigns plausible colors from the material while retaining fine residuals at their original coordinates. Native alpha-zero pixels bypass color correction exactly. Inspect region overlays, protected-pixel equality, palette distribution, local fine contrast, gamut handling and seams. A correct mask does not by itself prove a natural-looking recolored material; protected dark or colored rims can remain visible. See the source-specific provenance and generation commands alongside each prepared example.

An atlas with `N` source tiles per axis must have dimensions `N × source_width` by `N × source_height`. Keep each source tile at native resolution. For a 1024² source, 2×2, 3×3 and 4×4 layouts are 2048², 3072² and 4096². These dimensions describe storage; quality gates decide which layout is retained. Random assignment can leave a repeating mean hue for each original brick even when the global palette histogram is balanced. Compact layouts need an assignment audit and matched image checks, not just a smaller PNG.

Import atlas RGBA losslessly with mipmaps and repeat. Use identity channel mapping, `process/fix_alpha_border=false`, `process/premult_alpha=false`, and no automatic normal/roughness processing or lossy 3D compression. Keep RGB under zero alpha. The shader decodes RGB as source color and alpha as linear guard data; it does not write spatial transparency. [Packed-channel import details](../guard_optimization/PACKING.md) explain why these settings matter.

Bind the original matching PBR maps and source albedo, then configure:

| Parameter | Setting |
| --- | --- |
| `detile_enabled`, `structure_enabled`, `structure_guard_enabled` | `true` |
| `brick_individual_enabled` | `true` |
| `brick_individual_stochastic` | `true` for the source-aligned variant mixture |
| `brick_individual_map` | Prepared color atlas |
| `brick_individual_tiles_per_axis` | Exactly the atlas's source-tile count; default is `4` |
| `normal_map` | Matching original source normal, at original UV scale |
| `roughness_map`, `use_roughness_map` | Matching original roughness, optionally enabled |
| `texture_scale_m` | World span of one original source repeat, not the whole atlas |
| `variation_seed` | World arrangement of the available variants; not a new baked palette |

For an ordinary protected-mode comparison, bind the original packed albedo with `structure_guard_in_albedo_alpha=true`, or a separate linear `structure_guard_map`. Original source UVs and the template lattice remain the reference. Do not turn filtered region IDs into integers in a runtime shader; this implementation filters ordinary variant color instead.

The new route mixes only integer source-tile offsets and samples original normal/roughness at original UVs. It bypasses coherent donor mixtures and donor detrending so fine PBR coordinates remain aligned. Alpha-zero source color is selected before the coarse color fade, which prevents a protected pixel from punching a sharp hole through distant filtering. A supplied atlas cannot remove original repeated joint geometry, and triplanar blending still combines different projected layouts at corners or on curved surfaces.

Validate new sources with native close/grazing images, distant color/luminance repeat measurements, palette/fine-detail retention, exact protected input pixels, rendered protected PBR and matched camera motion. Test both the original source period and the atlas period. Report unfavorable views and tails; do not count a uniform gray result or unrelated macro variance as successful color detiling.

Memory estimates are theoretical uncompressed RGBA8 texel storage including mipmaps: approximately 5.3 MiB for a 1024² source, 21.3 MiB for a 2048² atlas, 48 MiB for 3072², and 85.3 MiB for 4096². Binding one texture does not establish resource residency, and these estimates are not measured VRAM or process allocation. The full-PBR stochastic route uses fifteen source-level texture reads when resolved and at most sixteen with its shared coarse mean; direct-atlas ablation uses nine. Timing must be measured separately on the target scene and renderer.
