# Hex Detiling shader

Copy this `hex_detile` folder into `res://addons/hex_detile/`. Create a ShaderMaterial, select `hex_detile.gdshader`, and set repeatable albedo and matching OpenGL normal textures. Enable mipmaps on both textures. Set `texture_scale_m` for the size in world units and adjust `normal_strength`, `detile_blend_power`, and `detile_detrend` to taste. Tone normalization defaults to off because it can suppress texture detail. `detile_enabled` switches the sampling mode.

Optional: enable the Hex Detiling editor plugin in Project Settings, select a MeshInstance3D with no material override, and use the dock to create a material. The creation is undoable and will not replace an existing override. Projection is world-space. Rotation, blend contrast, and a deterministic variation seed are adjustable. Enable `paper_blend` to try luminance-weighted color and roughness plus slope-weighted normal blending; this can change how maps blend relative to one another. Roughness uses a constant unless a matching map is assigned and enabled. It costs more texture samples than ordinary tiling and can alter contrast. Profile your own scene.

The full repository includes the demo, comparisons, benchmarks, and credits. Code is MIT licensed; see LICENSE and THIRD_PARTY_NOTICES.md.
