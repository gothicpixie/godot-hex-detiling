# Hex Detiling shader

Copy this `hex_detile` folder into `res://addons/hex_detile/`. Create a ShaderMaterial, select `hex_detile.gdshader`, and set repeatable albedo and matching OpenGL normal textures. Enable mipmaps on both textures. Set `texture_scale_m` for the size in world units and adjust `normal_strength`, `detile_blend_power`, and `detile_detrend` to taste. `detile_enabled` switches the sampling mode.

This is a shader asset, not an editor plugin; there is nothing to enable in Project Settings. Projection is world-space, and the material uses constant roughness. It costs more texture samples than ordinary tiling and can alter contrast. Profile your own scene.

The full repository includes the demo, comparisons, benchmarks, and credits. Code is MIT licensed; see LICENSE and THIRD_PARTY_NOTICES.md.
