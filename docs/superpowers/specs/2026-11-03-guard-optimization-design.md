# Mortar guard sampling optimization

Preserve v0.6.0's material mixture and generic separate-mask API. Add opt-in `structure_guard_in_albedo_alpha=false`: matching-resolution linear mask values occupy albedo alpha and share the exact reference/donor RGBA fetches that supply color. RGB remains sRGB source color. Mask footprint uses the albedo dimensions in packed mode and separate mask dimensions otherwise; the existing two-to-eight-texel fade remains unchanged.

Compute derivatives before data-dependent flow. If guard detail is exactly zero or reference mask is exactly zero, return original color, normalized original normal slope, and original optional roughness using explicit gradients. Do not approximate near-zero values, skip individually masked normals, change coherent normalization, detrend protected color, or renormalize surviving donors. Keep the unguarded coherent arithmetic unchanged wherever practical.

The demo binds packed Brick 4 only when protection is active with structure and detiling. It restores the original albedo otherwise, preserves checkbox preference and blend selection, and adds no UI option for texture packing. The generic addon still accepts a separate linear mask and defaults to the original behavior.

Measure frozen v0.6.0, packing alone, early return alone, and both with comparable whole-frame measurements; engine GPU timers previously returned zero. Shipping choice follows measured results and matched-output GPU checks, including motion and the mask fade transition. Do not claim GPU timing or exact floating-point identity from quantized captures. Existing source textures and regular tiling appearance remain unchanged.
