# Hex Detiling shader

Copy this entire `hex_detile` folder, including both `hex_detile.gdshader` and its required `coherent_blend.gdshaderinc`, into `res://addons/hex_detile/`. Create a ShaderMaterial, select `hex_detile.gdshader`, and set repeatable albedo and matching OpenGL normal textures. Enable mipmaps on both textures. Set `texture_scale_m` for the size in world units and adjust `normal_strength`, `detile_blend_power`, and `detile_detrend` to taste. Tone normalization defaults to off because it can suppress texture detail. `detile_enabled` switches the sampling mode.

Optional: enable the Hex Detiling editor plugin in Project Settings, select a MeshInstance3D with no material override, and use the dock to create a material. The creation is undoable and will not replace an existing override. Projection is world-space. Rotation, blend contrast, and a deterministic variation seed are adjustable. Enable `paper_blend` to try luminance-weighted color and roughness plus slope-weighted normal blending; this can change how maps blend relative to one another. Roughness uses a constant unless a matching map is assigned and enabled. It costs more texture samples than ordinary tiling and can alter contrast. Profile your own scene.

The full repository includes the demo, comparisons, benchmarks, and credits. Code is MIT licensed; see LICENSE and THIRD_PARTY_NOTICES.md.

## Optional coherent mode

The default remains shared geometric weights (`coherent_blend=false`, `paper_blend=false`). Set `coherent_blend=true` for a content-guided mixture shared by color, normal slopes, and optional roughness. It takes precedence over `paper_blend`. Brightness and normal relief guide the mixture; `paper_falloff` sets content influence and `normal_strength` also controls the normal cue. Roughness follows the common mixture without steering it. `normal_blend_contrast` applies only to paper mode.

`coherent_filter=true` defaults on but only affects coherent mode. It relaxes sharp weights and content guidance with screen footprint, while keeping gradient-based texture sampling. This is heuristic blend relaxation, not a complete anti-aliasing solution, and can soften detail. No additional texture reads are needed relative to existing detiling at the same roughness and detrending settings. Default full PBR triplanar detiling uses 27 source-level texture reads (18 without roughness); optional detrending adds 12. Compiler and hardware costs still need profiling.

The full repository's `docs/coherent/README.md` describes the method, bounded fixture results, seventeen-material captures, structured-pattern failures, and reproduction commands. Shared weights already align map mixtures; the new mode should be selected by comparison on your own material.

## Optional structure-aware transforms

Set `structure_enabled=true` to replace free offsets and rotations with seeded integer translations on a supplied source lattice, independently of the selected blend mode. `structure_period` is the X/Y step in source UV (`1` means a full image repeat); `structure_stagger` adds that fraction of the X period per Y step. Each integer lies in `[-4,4]`. Zero period components lock their coordinate. Rotation is forced to identity while enabled. All maps share the transform and no texture reads are added.

Supply periods that preserve the motif, including checker color parity. Full-image-repeat shifts yield identical samples and no meaningful variation. Scanned layouts rarely match an ideal lattice exactly, so misalignment or ghosting can remain; this does not recognize patterns automatically. Constraints apply per triplanar projection and cannot enforce a global layout around corners. The demo offers approximate source-specific brick, plank, and checker presets; see the full repository's `docs/structure/README.md` for values, limitations, and evidence.

## Optional source-mask protection

Set `structure_guard_enabled=true` with `structure_enabled` and `detile_enabled`, and assign `structure_guard_map` as repeating mipmapped linear data. Black retains the original source material; white permits variation only when the donor mask is also safe. Missing maps default black. Rejected donor weight returns to the source without renormalizing surviving donors, with one common mixture for albedo, normal slopes and roughness. Active protection uses coherent blending regardless of the selected blend mode. The option defaults off and leaves existing presets unchanged.

Supply a conservative aligned mask; the addon does not segment materials automatically. Donor participation fades from full at two mask texels per pixel to zero at eight, returning to the original appearance at distance. This heuristic does not skip texture reads or guarantee alias-free filtering. Original pattern repetition remains, interior variation is restricted, and triplanar corners still mix projected layouts. Detrending changes donor color while protected source color remains raw, which can produce transition tone differences.

With full PBR and no detrending, guarding adds 21 source-level triplanar reads, increasing 27 to 48. Whole-frame intervals on Apple M5 / Godot 4.7.2 Compatibility increased from 3.435 to 5.626 ms in one controlled demo run; these are not GPU timings or a general cost estimate. Profile your scene. The full repository's `docs/brick_guard/README.md` contains matched native crops, mask provenance, validation and benchmark links. The generic MIT addon excludes the example CC0 Brick 4 mask and source textures; obtain or author an appropriate mask for your own material.
