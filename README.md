# Hex Detiling for Godot

**Break up repeated rock, dirt, sand, and other organic textures across large 3D surfaces.** This Godot 4 shader uses stochastic hex-style tiling and world-space triplanar projection, with shared offsets and optional rotation for albedo, normal, and roughness maps.

![A loop alternating between regular tiling and hex detiling on the same rock surface](docs/comparison.gif)

The loop alternates two actual captures of the same terrain, camera, lights, and material settings. Detiling reduces the obvious repeating marks, but also changes contrast and costs more sampling work. It is not a one-click fix for every texture.

## Try the demo

1. Open `project.godot` in Godot 4 and allow the textures to import.
2. Press **F5** to run. Press **Space** or click the button to toggle the effect.
3. Press **1**, **2**, or **3** for camera views. Choose a texture set, adjust rotation and blend contrast, and toggle the roughness map in the panel. Drag to rotate the surface and use the mouse wheel to zoom.

Tested with Godot **4.7.2**, Compatibility renderer, on macOS. Other versions and hardware need testing. From a terminal, run `godot --path . --editor --quit` to import, then `godot --path .`.

| Front: regular | Front: detiled |
| --- | --- |
| ![Front view with ordinary tiling](docs/periodic.png) | ![Front view with detiling](docs/detiled.png) |
| **Oblique: regular** | **Oblique: detiled** |
| ![Oblique view with ordinary tiling](docs/oblique-periodic.png) | ![Oblique view with detiling](docs/oblique.png) |
| **Elevated: regular** | **Elevated: detiled** |
| ![Elevated view with ordinary tiling](docs/elevated-periodic.png) | ![Elevated view with detiling](docs/elevated.png) |

### A second material

The following captures use Sandstone Cracks, with rotation at 0.75, blend contrast at 0.65, and roughness-map sampling enabled. The left and right images use the same camera and material settings apart from the detiling toggle.

| Regular | Detiled |
| --- | --- |
| ![Sandstone with regular tiling](docs/sandstone-periodic.png) | ![Sandstone with detiling](docs/sandstone-detiled.png) |

## Add it to your project

Copy [`addons/hex_detile`](addons/hex_detile) to your project's `addons` folder. Create a **ShaderMaterial**, select `hex_detile.gdshader`, and assign a repeatable albedo map and its matching OpenGL-style normal map. Enable mipmaps on both textures in the Godot Import dock. Set `texture_scale_m` to control the world-space repeat size, and tune the other controls in the inspector. Optionally enable **Hex Detiling** under Project Settings → Plugins. Select one MeshInstance3D without a material override and use the dock to create a ShaderMaterial; assign its textures and tune its parameters in the Inspector. The action is undoable and will not replace an existing override. The shader also works without enabling the plugin.

The shader is a complete spatial material. To use it in an existing custom material, integrate its sampling functions and fragment logic into that shader. The material uses constant roughness by default; enable `use_roughness_map` and assign a matching map to use texture roughness. Height maps are not sampled.

| Control | Purpose |
| --- | --- |
| `detile_enabled` | Compare stochastic and ordinary periodic sampling. |
| `texture_scale_m` | Size of one repeat in world units, normally meters. |
| `rotation_strength` | Rotate cell samples; zero preserves the source orientation. |
| `blend_contrast` | Adjust the weight curve; 0.5 is neutral. Higher values sharpen transitions and may reveal the lattice. |
| `use_roughness_map`, `roughness_map` | Enable and assign a matching roughness texture. |
| `detile_blend_power` | Sharpen the blend between offset samples. |
| `detile_detrend` | Adjust color tone normalization; zero disables it. |
| `detile_detrend_lod` | Normalization blur level relative to a 512-pixel map; scales with texture dimensions. |
| `normal_strength`, `roughness` | Appearance controls shared by both modes. |

## How it works and when to use it

The shader samples three randomly offset copies of a repeatable texture on a triangular lattice, blends them, and projects the result along three world axes. The material maps share cell offsets, rotations, and geometric blend weights. Optional rotation transforms texture derivatives for mip selection and rotates sampled normal components back into projection space. Rotation is off by default; directional textures may work better without it. `blend_contrast` changes the blend-weight curve to retain more definition, but high values can expose the grid; it does not guarantee contrast preservation. Optional tone normalization can reduce broad patches but can change color or suppress features; it defaults to off. World-space projection means moving or rotating an object moves it through the texture. Normal mapping remains an approximation based on the geometric normal and sampled tangent components, not a general substitute for a mesh's tangent-space material.

Large organic surfaces are a useful starting point. Strong, recognizable features can still repeat or form patches. Triplanar projection, multiple texture samples, and normalization add GPU work; this demo has no distance-based optimization. See the [benchmark and its limitations](benchmarks/README.md), and profile on your target hardware.

## Project checks

After importing assets, run `godot --headless --path . --script res://tests/smoke.gd` to check scene loading, texture binding, and the sampling toggle. On a machine with a graphics display, `godot --path . --script res://tests/gpu_probe.gd` checks that a flat normal map leaves lighting unchanged at full rotation, and `godot --path . --script res://tests/capture.gd` regenerates the still images in `docs/`. These checks do not establish correctness for every normal map or renderer.

## Credits and license

Adapted from the author's `chain-racing` material and cliff study. Based on Morten S. Mikkelsen's [Practical Real-Time Hex-Tiling](https://jcgt.org/published/0011/03/05/), JCGT, 2022. This adaptation adds optional cell rotation, a shared blend-weight curve, and multiplicative color normalization; it is not a verbatim implementation of every technique in the paper. See [third-party notices](addons/hex_detile/THIRD_PARTY_NOTICES.md) for the original Godot reference and its license.

Code and documentation: [MIT License](LICENSE). The example texture sets are [Rocks Ground 04](https://polyhaven.com/a/rocks_ground_04) and [Sandstone Cracks](https://polyhaven.com/a/sandstone_cracks), by Rob Tuytel / Poly Haven, under [CC0](https://polyhaven.com/license). The sandstone maps were resized to 1024 pixels for this demo. Screenshots depict those textures. Godot is distributed separately under its own license.
