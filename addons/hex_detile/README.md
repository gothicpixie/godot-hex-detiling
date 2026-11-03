# Hex Detiling shader

Copy this entire `hex_detile` folder, including both `hex_detile.gdshader` and its required `coherent_blend.gdshaderinc`, into `res://addons/hex_detile/`. Create a ShaderMaterial, select `hex_detile.gdshader`, and set repeatable albedo and matching OpenGL normal textures. Enable mipmaps on both textures. Set `texture_scale_m` for the size in world units and adjust `normal_strength`, `detile_blend_power`, and `detile_detrend` to taste. Tone normalization defaults to off because it can suppress texture detail. `detile_enabled` switches the sampling mode.

Optional: enable the Hex Detiling editor plugin in Project Settings, select a MeshInstance3D with no material override, and use the dock to create a material. The creation is undoable and will not replace an existing override. Projection is world-space. Rotation, blend contrast, and a deterministic variation seed are adjustable. Enable `paper_blend` to try luminance-weighted color and roughness plus slope-weighted normal blending; this can change how maps blend relative to one another. Roughness uses a constant unless a matching map is assigned and enabled. It costs more texture samples than ordinary tiling and can alter contrast. Profile your own scene.

The full repository includes the demo, comparisons, benchmarks, and credits. Code is MIT licensed; see LICENSE and THIRD_PARTY_NOTICES.md.

## Optional coherent mode

The default remains shared geometric weights (`coherent_blend=false`, `paper_blend=false`). Set `coherent_blend=true` for a content-guided mixture shared by color, normal slopes, and optional roughness. It takes precedence over `paper_blend`. Brightness and normal relief guide the mixture; `paper_falloff` sets content influence and `normal_strength` also controls the normal cue. Roughness follows the common mixture without steering it. `normal_blend_contrast` applies only to paper mode.

`coherent_filter=true` defaults on but only affects coherent mode. It relaxes sharp weights and content guidance with screen footprint, while keeping gradient-based texture sampling. This is heuristic blend relaxation, not a complete anti-aliasing solution, and can soften detail. No additional texture reads are needed relative to existing detiling at the same roughness and detrending settings. Default full PBR triplanar detiling uses 27 source-level texture reads (18 without roughness); optional detrending adds 12. Compiler and hardware costs still need profiling.

The full repository's `docs/coherent/README.md` describes the method, bounded fixture results, seventeen-material captures, structured-pattern failures, and reproduction commands. Shared weights already align map mixtures; the new mode should be selected by comparison on your own material.
