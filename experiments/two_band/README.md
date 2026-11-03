# Exploratory two-band color blend

This is a **prototype**, not a supported shader mode. It was motivated by Bartlomiej Wronski's [GPU-Friendly Laplacian Texture Blending](https://jcgt.org/published/0014/01/02/) (2025). That paper uses multiple Laplacian bands with different mask scales; this prototype is only a two-band approximation and is not an implementation or validation of the published method.

The patch takes three lower-frequency color samples with gradients scaled by four, subtracts them from the existing samples, blends those residuals with the existing paper-mode weights, and blends the lower-frequency samples with barycentric weights. It affects albedo only; normals and roughness continue using the existing paper mode. Existing mipmaps are required. This is an experiment with a different blend, not a claim of better map alignment or consistent filtering.

## Check performed

On November 3, 2026, we captured the six-material stress-test scene at 1280 × 720 in Godot 4.7.2 Compatibility on Apple M5, with paper weighting, rotation 0.65, blend contrast 0.65, and roughness sampling enabled. The comparison toggled only the prototype, at a two-mip footprint. [cobble-paper.jpg](cobble-paper.jpg) and [cobble-two-band.jpg](cobble-two-band.jpg) are the corresponding captures; both are JPEGs produced by Godot.

A simple 640 × 360 center-crop luminance edge-filter proxy decreased slightly for all six tested materials: brick 25.374 → 25.102; wood 5.872 → 5.763; grass 5.873 → 5.704; denim 5.895 → 5.823; paving 10.367 → 9.855; cobblestone 18.034 → 17.848, in 8-bit image units. This crude measure includes scene lighting, geometry, JPEG compression, and different amounts of background; it does not measure perceptual quality or establish the published method's performance. The visual difference was modest and we did not establish a consistent improvement. We did not measure GPU time or test camera motion, halos, overshoot, or anisotropic minification. Consequently, the experiment was not added to the shipped shader.

`prototype.patch` contains the exploratory change against repository commit `2ade88c`. Apply it only in a separate checkout with `git apply prototype.patch`, import the project, and run `godot --path . --script res://tests/variety_gallery.gd` on a GPU-backed display. The patch adds a `multiscale` capture mode. The current version of the shader has evolved since that commit; the patch is retained for research, not guaranteed to apply to current `main`.
