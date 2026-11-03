# Hex Detiling for Godot

**Break up repeated rock, dirt, sand, and other organic textures across large 3D surfaces.** This Godot 4 shader uses stochastic hex-style tiling and world-space triplanar projection, with matching offsets for albedo and normal maps.

![A loop alternating between regular tiling and hex detiling on the same rock surface](docs/comparison.gif)

The loop alternates two actual captures of the same terrain, camera, lights, and material settings. Detiling reduces the obvious repeating marks, but also changes contrast and costs more sampling work. It is not a one-click fix for every texture.

## Try the demo

1. Open `project.godot` in Godot 4 and allow the textures to import.
2. Press **F5** to run. Press **Space** or click the button to toggle the effect.
3. Press **1**, **2**, or **3** for front, oblique, or elevated views. Drag to rotate the surface and use the mouse wheel to zoom.

Tested with Godot **4.7.2**, Compatibility renderer, on macOS. Other versions and hardware need testing. From a terminal, run `godot --path . --editor --quit` to import, then `godot --path .`.

| Front: regular | Front: detiled |
| --- | --- |
| ![Front view with ordinary tiling](docs/periodic.png) | ![Front view with detiling](docs/detiled.png) |
| **Oblique: regular** | **Oblique: detiled** |
| ![Oblique view with ordinary tiling](docs/oblique-periodic.png) | ![Oblique view with detiling](docs/oblique.png) |
| **Elevated: regular** | **Elevated: detiled** |
| ![Elevated view with ordinary tiling](docs/elevated-periodic.png) | ![Elevated view with detiling](docs/elevated.png) |

## Add it to your project

Copy [`addons/hex_detile`](addons/hex_detile) to your project's `addons` folder. Create a **ShaderMaterial**, select `hex_detile.gdshader`, and assign a repeatable albedo map and its matching OpenGL-style normal map. Enable mipmaps on both textures in the Godot Import dock. Set `texture_scale_m` to control the world-space repeat size, and tune the other controls in the inspector. This is a shader asset, so there is **no editor plugin to enable**.

The shader is a complete spatial material. To use it in an existing custom material, integrate its sampling functions and fragment logic into that shader. The material uses constant roughness and does not sample roughness or height maps.

| Control | Purpose |
| --- | --- |
| `detile_enabled` | Compare stochastic and ordinary periodic sampling. |
| `texture_scale_m` | Size of one repeat in world units, normally meters. |
| `detile_blend_power` | Sharpen the blend between offset samples. |
| `detile_detrend` | Adjust color tone normalization; zero disables it. |
| `detile_detrend_lod` | Normalization blur level relative to a 512-pixel map; scales with texture dimensions. |
| `normal_strength`, `roughness` | Appearance controls shared by both modes. |

## How it works and when to use it

The shader samples three randomly offset copies of a repeatable texture on a triangular lattice, blends them, and projects the result along three world axes. Color and normal maps share offsets. Optional tone normalization helps reduce broad patches from the blend, but can change contrast or suppress features. It defaults to off; the demo uses the off setting. Offset-only sampling preserves orientation; it does not rotate tiles. World-space projection means moving or rotating an object moves it through the texture. Normal mapping is an approximation based on the geometric normal and sampled tangent components, not a general substitute for a mesh's tangent-space material.

Large organic surfaces are a useful starting point. Strong, recognizable features can still repeat or form patches. Triplanar projection, multiple texture samples, and normalization add GPU work; this demo has no distance-based optimization. See the [benchmark and its limitations](benchmarks/README.md), and profile on your target hardware.

## Project checks

After importing assets, run `godot --headless --path . --script res://tests/smoke.gd` to check scene loading, texture binding, and the sampling toggle. On a machine with a graphics display, `godot --path . --script res://tests/capture.gd` regenerates the still images in `docs/`.

## Credits and license

Adapted from the author's `chain-racing` material and cliff study. Based on Morten S. Mikkelsen's [Practical Real-Time Hex-Tiling](https://jcgt.org/published/0011/03/05/), JCGT, 2022. This is an offset-only adaptation with multiplicative color normalization, not a verbatim implementation of every technique in the paper. See [third-party notices](addons/hex_detile/THIRD_PARTY_NOTICES.md) for the original Godot reference and its license.

Code and documentation: [MIT License](LICENSE). The two example texture maps are [Rocks Ground 04](https://polyhaven.com/a/rocks_ground_04), by Rob Tuytel / Poly Haven, under [CC0](https://polyhaven.com/license). Screenshots depict those textures. Godot is distributed separately under its own license.
