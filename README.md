# Hex Detiling for Godot

**Break up repeated rock, dirt, sand, and other organic textures across large 3D surfaces.** This Godot 4 shader uses stochastic hex-style tiling and world-space triplanar projection, with shared offsets and optional rotation for albedo, normal, and roughness maps.

![A loop alternating between regular tiling and hex detiling on the same rock surface](docs/comparison.gif)

The loop alternates two actual captures of the same terrain, camera, lights, and material settings. Detiling reduces the obvious repeating marks, but also changes contrast and costs more sampling work. It is not a one-click fix for every texture.

## Try the demo

1. Open `project.godot` in Godot 4 and allow the textures to import.
2. Press **F5** to run. Press **Space** or click the button to toggle the effect.
3. Press **1**, **2**, or **3** for camera views. Choose one of nine texture sets, adjust rotation and blend contrast, and toggle paper-inspired weighting and the roughness map in the panel. Drag to rotate the surface and use the mouse wheel to zoom.

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

### Material and mesh gallery

These GPU captures compare the same camera, lighting, mesh, and material settings with detiling off and on. All four use rotation strength **0.65**, blend contrast **0.65**, and the matching roughness map. The repeat size is **1.5 m** for Rocks Ground and Sandstone Cracks, and **2.5 m** for Rock Boulder Cracked. Each image uses albedo, normal, and roughness maps. They are visual examples, not a proof that seams or artifacts are absent under every light or viewing distance.

| Material / mesh | Regular tiling | Detiling |
| --- | --- | --- |
| Rocks Ground 04 on procedural terrain | ![Rocks terrain, regular tiling](docs/gallery/rocks-terrain-periodic.png) | ![Rocks terrain, detiled](docs/gallery/rocks-terrain-detiled.png) |
| Sandstone Cracks on a sphere | ![Sandstone sphere, regular tiling](docs/gallery/sandstone-sphere-periodic.png) | ![Sandstone sphere, detiled](docs/gallery/sandstone-sphere-detiled.png) |
| Rock Boulder Cracked on a vertical box | ![Cracked rock wall, regular tiling](docs/gallery/boulder-wall-periodic.png) | ![Cracked rock wall, detiled](docs/gallery/boulder-wall-detiled.png) |
| Rock Boulder Cracked on a sphere | ![Cracked rock sphere, regular tiling](docs/gallery/boulder-sphere-periodic.png) | ![Cracked rock sphere, detiled](docs/gallery/boulder-sphere-detiled.png) |

The cracked-rock wall makes the regular grid especially easy to see; the detiled version breaks it up, but changes and softens some detail. The sandstone sphere has less prominent repetition to begin with, so the difference is subtler. These are three rock or sandstone materials; they do not establish performance on wood, brick, or strongly directional textures. Sphere and box examples are controlled primitive meshes, not scans or detailed production assets.

### Wider material stress test

These examples use six additional CC0 materials on a vertical box, terrain, or sphere. Each row holds the camera, lighting, maps, roughness sampling, and blend contrast (0.65) fixed. The middle column enables detiling with **rotation 0**; the last uses **rotation 0.65**. Texture repeat size is 2.5 m for brick, wood, paving, and cobblestone and 1.5 m for grass and denim. Images were captured in Godot 4.7.2 Compatibility on Apple M5.

| Material / mesh | Regular tiling | Detiled, no rotation | Detiled, rotation 0.65 |
| --- | --- | --- | --- |
| Brick / box | ![Regular brick](docs/variety/brick-periodic.jpg) | ![Brick with offsets](docs/variety/brick-offset.jpg) | ![Brick with offsets and rotation](docs/variety/brick-rotated.jpg) |
| Wood planks / box | ![Regular wood](docs/variety/wood-periodic.jpg) | ![Wood with offsets](docs/variety/wood-offset.jpg) | ![Wood with offsets and rotation](docs/variety/wood-rotated.jpg) |
| Grass / terrain | ![Regular grass](docs/variety/grass-periodic.jpg) | ![Grass with offsets](docs/variety/grass-offset.jpg) | ![Grass with offsets and rotation](docs/variety/grass-rotated.jpg) |
| Denim / sphere | ![Regular denim](docs/variety/denim-periodic.jpg) | ![Denim with offsets](docs/variety/denim-offset.jpg) | ![Denim with offsets and rotation](docs/variety/denim-rotated.jpg) |
| Checkered paving / box | ![Regular paving](docs/variety/paving-periodic.jpg) | ![Paving with offsets](docs/variety/paving-offset.jpg) | ![Paving with offsets and rotation](docs/variety/paving-rotated.jpg) |
| Cobblestone / terrain | ![Regular cobblestone](docs/variety/cobble-periodic.jpg) | ![Cobblestone with offsets](docs/variety/cobble-offset.jpg) | ![Cobblestone with offsets and rotation](docs/variety/cobble-rotated.jpg) |

### Comparing blend modes

Paper-inspired weighting is optional and **off by default**. The following images compare it with the existing shared-weight mode, using the same textures, rotation (0.65), roughness maps, lighting, and camera. Paper mode uses falloff 0.6 and normal blend contrast 0.5; both modes use color blend contrast 0.65. See the six `*-paper.jpg` images in [`docs/variety`](docs/variety/) for the rest of the set.

![Cobblestone and brick comparing shared weights with paper-inspired weights](docs/variety/paper-comparison.jpg)

Differences in these renders are modest, and the paper-inspired mode does not repair the broken brick pattern. Separate per-map weights can also change the alignment of blended features, even though the cell transforms are shared. Choose the mode by comparing your own material; these examples do not establish that either is universally better.

**What to look for:** The stochastic sampling disrupts the regular mortar lines, planks, and checkerboard; rotation makes that especially obvious. Turning rotation off preserves orientation but random offsets can still break alignment. These are failure cases for architecture that must retain its pattern, not examples of a seamless structural fix. Grass, denim, and irregular stone are less constrained, although blending can still soften details or create patches. The terrain, sphere, and box are controlled examples; results will vary with scale, lighting, source textures, and geometry.

## Add it to your project

Copy [`addons/hex_detile`](addons/hex_detile) to your project's `addons` folder. Create a **ShaderMaterial**, select `hex_detile.gdshader`, and assign a repeatable albedo map and its matching OpenGL-style normal map. Enable mipmaps on both textures in the Godot Import dock. Set `texture_scale_m` to control the world-space repeat size, and tune the other controls in the inspector. Optionally enable **Hex Detiling** under Project Settings → Plugins. Select one MeshInstance3D without a material override and use the dock to create a ShaderMaterial; assign its textures and tune its parameters in the Inspector. The action is undoable and will not replace an existing override. The shader also works without enabling the plugin.

The shader is a complete spatial material. To use it in an existing custom material, integrate its sampling functions and fragment logic into that shader. The material uses constant roughness by default; enable `use_roughness_map` and assign a matching map to use texture roughness. Height maps are not sampled.

| Control | Purpose |
| --- | --- |
| `detile_enabled` | Compare stochastic and ordinary periodic sampling. |
| `texture_scale_m` | Size of one repeat in world units, normally meters. |
| `rotation_strength` | Rotate cell samples; zero preserves the source orientation. |
| `blend_contrast` | Adjust the color and roughness weight curve (and normals in shared-weight mode); 0.5 is neutral. Higher values may reveal the lattice. |
| `paper_blend` | Enable luminance-weighted color and roughness blending and slope-weighted normal blending. Off by default. |
| `paper_falloff` | Controls how strongly sample luminance or slope modifies weights in paper mode; default 0.6. |
| `normal_blend_contrast` | Weight curve for normal samples in paper mode; 0.5 is neutral. |
| `use_roughness_map`, `roughness_map` | Enable and assign a matching roughness texture. |
| `detile_blend_power` | Sharpen the blend between offset samples. |
| `detile_detrend` | Adjust color tone normalization; zero disables it. |
| `detile_detrend_lod` | Normalization blur level relative to a 512-pixel map; scales with texture dimensions. |
| `normal_strength`, `roughness` | Appearance controls shared by both modes. |

## How it works and when to use it

The shader samples three randomly offset copies of a repeatable texture on a triangular lattice, blends them, and projects the result along three world axes. The material maps share cell offsets and rotations. In the default mode they also share geometric blend weights; optional paper-inspired weighting calculates weights separately for color, roughness, and normals, which can shift how corresponding features blend. Optional rotation transforms texture derivatives for mip selection and rotates sampled normal components back into projection space. Rotation is off by default; directional textures may work better without it. `blend_contrast` changes the blend-weight curve to retain more definition, but high values can expose the grid; it does not guarantee contrast preservation. Optional tone normalization can reduce broad patches but can change color or suppress features; it defaults to off. World-space projection means moving or rotating an object moves it through the texture. In paper-inspired mode, color and roughness weights use sample luminance; normal samples are converted to slopes, weighted by slope magnitude, and blended before normal reconstruction. The implementation reconstructs normal Z from XY and caps grazing slopes for stability. This adapts the paper to the triplanar material; it is not a complete or exact reproduction. Normal mapping remains an approximation based on the geometric normal and sampled tangent components, not a general substitute for a mesh's tangent-space material.

Large organic surfaces are a useful starting point. Strong, recognizable features can still repeat or form patches. Triplanar projection, multiple texture samples, and normalization add GPU work; this demo has no distance-based optimization. See the [benchmark and its limitations](benchmarks/README.md), and profile on your target hardware.

## Project checks

After importing assets, run `godot --headless --path . --script res://tests/smoke.gd` to check scene loading, texture binding, and the sampling toggle. On a machine with a graphics display, `godot --path . --script res://tests/gpu_probe.gd` checks that a flat normal map leaves lighting unchanged at full rotation. Run `godot --path . --script res://tests/capture.gd` to regenerate the initial stills, or `godot --path . --script res://tests/material_gallery.gd` for the paired material and mesh gallery in `docs/gallery/`. Run `godot --path . --script res://tests/variety_gallery.gd` to regenerate the six-material stress test in `docs/variety/`. These checks do not establish correctness for every normal map or renderer.

## Credits and license

Adapted from the author's `chain-racing` material and cliff study. Based on Morten S. Mikkelsen's [Practical Real-Time Hex-Tiling](https://jcgt.org/published/0011/03/05/), JCGT, 2022. This adaptation includes optional cell rotation, blend-weight curves, and a paper-inspired mode for luminance- and slope-based weighting; it also offers a separate multiplicative color normalization. It is not a verbatim implementation of every technique in the paper. See [third-party notices](addons/hex_detile/THIRD_PARTY_NOTICES.md) for the original Godot reference and its license.

Code and documentation: [MIT License](LICENSE). The example texture sets are [Rocks Ground 04](https://polyhaven.com/a/rocks_ground_04) and [Sandstone Cracks](https://polyhaven.com/a/sandstone_cracks), by Rob Tuytel / Poly Haven, plus [Rock Boulder Cracked](https://polyhaven.com/a/rock_boulder_cracked), photography by Dimitrios Savva and processing by Dario Barresi / Poly Haven. All are [CC0](https://polyhaven.com/license). The sandstone and boulder maps were resized to 1024 pixels for this demo. Screenshots depict those textures. Godot is distributed separately under its own license.

Additional gallery maps are from Poly Haven under [CC0](https://polyhaven.com/license): [Brick 4](https://polyhaven.com/a/brick_4) and [Denim Fabric](https://polyhaven.com/a/denim_fabric) by Rob Tuytel; [Dark Wooden Planks](https://polyhaven.com/a/dark_wooden_planks) and [Checkered Pavement Tiles](https://polyhaven.com/a/checkered_pavement_tiles) by Amal Kumar; [Grass Ground](https://polyhaven.com/a/grass_ground) by Charlotte Baglioni; and [Cobblestone 01](https://polyhaven.com/a/cobblestone_01) by Rob Tuytel. The 1K maps and their source URLs and checksums are listed in [SOURCES.json](assets/gallery/SOURCES.json).
