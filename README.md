# Hex Detiling for Godot

**Break up repeated rock, dirt, sand, and other organic textures across large 3D surfaces.** This Godot 4 shader uses stochastic hex-style tiling and world-space triplanar projection, with shared offsets and optional rotation for albedo, normal, and roughness maps.

The demo includes **19 CC0 source material sets**. [Browse the source albedo previews](docs/brick_atlas_release/source-albedo-palette-19.png); these are textures, not shader renders. The original [17-material render comparison](docs/coherent/README.md#seventeen-material-gallery) remains a historical matched test. Brick 4 is the qualified brick-palette preset; the two new brick sources are documented authoring examples with palette controls disabled.

![A loop alternating between regular tiling and hex detiling on the same rock surface](docs/comparison.gif)

The loop alternates two actual captures of the same terrain, camera, lights, and material settings. Detiling reduces the obvious repeating marks, but also changes contrast and costs more sampling work. It is not a one-click fix for every texture.

## Prepared Brick 4 color variation

The opt-in palette mode varies actual brick interiors using source-aligned variants. In the accepted distant tests, source-repeat color correlation fell 56.7% / 59.2%, while inspected mortar stayed aligned and sharp. Joint shapes, weathering and some protected rims still repeat. The accepted 4×4 atlas requires about **85.3 MiB of theoretical uncompressed RGBA8 texels including mipmaps**. Smaller 2×2/3×3 trials missed at least one quality check, so they did not replace the default.

![Original Brick 4 left; accepted palette variation right, matched native crops](docs/brick_atlas_release/brick4-accepted-native.png)

Start with **Brick 4 → Mesh: Wall → Preserve pattern → Protect mortar → Vary individual brick colors**. This mode uses aligned original normal/roughness maps; near interiors deliberately differ from coherent donor mixtures. [Settings, failed compact trials, measured rendering costs, material examples and limits](docs/brick_atlas_release/README.md) include the unfavorable distant-wall cost as well as the improvements. Corner and curved triplanar layouts are not guaranteed to form continuous brick courses.

## Optional coherent material blending

The new **coherent material** mode uses color brightness and normal relief to guide one blend shared by albedo, normal slopes, and roughness. The existing shared-weight mode already keeps map weights aligned; coherent mode adds content guidance and optional relaxation as the pixel footprint grows. It is an opt-in experiment, with the original shared mode still the default.

![Matched moving-camera views of shared, paper-inspired, and coherent material blending](docs/coherent/camera-loop.gif)

The camera loop and [17-material comparison](docs/coherent/README.md) use matched settings across modes. Changes are often subtle. Structured brick, plank, and tile layouts still break, and distant relaxation can soften texture. The [detailed evidence](docs/coherent/README.md#controlled-checks) includes synthetic channel-alignment and footprint checks; these do not establish general visual or temporal superiority.

## Optional pattern preservation

Enable **Preserve pattern** in the demo for Brick 4, Dark Wooden Planks, or Checkered Pavement Tiles to try source-specific constrained translations. This opt-in setting ignores rotation and works independently of the blend selector. It uses approximate motif periods, so irregular mortar, plank seams, and wrapped source boundaries can still misalign. It does not recognize patterns automatically or enforce a global layout around triplanar corners. The [matched comparisons](docs/structure/README.md#evidence-and-reproduction) show checker grids and long plank seams retained more clearly than unconstrained offsets, while brick joints still soften or double. Periodic sampling remains the most faithful to the original layout. See [settings, measured presets, and evidence](docs/structure/README.md).

Brick 4 now offers a separate **Protect mortar** option after enabling Preserve pattern. It anchors masked mortar to the original source and permits variation only in safe source and donor interiors, using common coherent weights. It returns to original sampling at coarse footprints. This retains the repeating mortar layout, restricts interior variation, and adds texture reads; it depends on a source-aligned mask. The native comparison below shows periodic, existing structured, and guarded brick sampling. See [matched native crops, mask provenance, checks and cost](docs/brick_guard/README.md). The demo packs the guard into albedo alpha, reducing full PBR worst-case source-level reads from 48 to 36; exact source-only cases avoid donor sampling. The separate-mask API remains supported. See [packing requirements](docs/guard_optimization/PACKING.md) and [optimization measurements and motion](docs/guard_optimization/README.md); read counts are not timing estimates.

[Historical native comparison: periodic, structured and mortar-guarded brick](docs/brick_guard/native-comparison-seed0.jpg).

[Earlier unguarded brick, wood and paving comparisons](docs/structure/native-detail-crops.png).

The earlier [macro-tone experiment](docs/distant_brick/README.md) remains clearly experimental; it did not adequately remove the repeated colored patches.

## Try the demo

1. Open `project.godot` in Godot 4 and allow the textures to import.
2. Press **F5** to run. Press **Space** or click the button to toggle the effect.
3. For bricks, choose **Brick 4** and **Mesh: Wall**; enable **Preserve pattern**, **Protect mortar** and **Vary individual brick colors**. The palette option is validated for Brick 4; Red Brick and Large Red Bricks remain disabled authoring examples.
4. Choose among 19 source sets and Terrain, Wall, Box/corner or Cylinder. Press **1**, **2** or **3** for framed views; drag to rotate and use the wheel over the surface to zoom. The controls scroll in smaller windows. Organic surfaces retain the shared, paper-inspired and coherent comparison modes.

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

Copy the entire [`addons/hex_detile`](addons/hex_detile) folder to your project's `addons` folder, including `coherent_blend.gdshaderinc` alongside `hex_detile.gdshader`. Create a **ShaderMaterial**, select `hex_detile.gdshader`, and assign a repeatable albedo map and its matching OpenGL-style normal map. Enable mipmaps on both textures in the Godot Import dock. Set `texture_scale_m` to control the world-space repeat size, and tune the other controls in the inspector. Optionally enable **Hex Detiling** under Project Settings → Plugins. Select one MeshInstance3D without a material override and use the dock to create a ShaderMaterial; assign its textures and tune its parameters in the Inspector. The action is undoable and will not replace an existing override. The shader also works without enabling the plugin.

The shader is a complete spatial material. To use it in an existing custom material, integrate its sampling functions and fragment logic into that shader. The material uses constant roughness by default; enable `use_roughness_map` and assign a matching map to use texture roughness. Height maps are not sampled.

| Control | Purpose |
| --- | --- |
| `detile_enabled` | Compare stochastic and ordinary periodic sampling. |
| `texture_scale_m` | Size of one repeat in world units, normally meters. |
| `variation_seed` | Choose a different deterministic cell-offset and rotation pattern; 0 preserves the original pattern. Matching maps share the seed. Duplicate the material to give different surfaces different seeds. |
| `rotation_strength` | Rotate cell samples; zero preserves the source orientation. Ignored while `structure_enabled` is on. |
| `structure_enabled` | Constrain cell transforms to a source-specific lattice and force identity rotation. Off by default; independent of blending. |
| `structure_guard_enabled`, `structure_guard_map` | Optional source-mask protection, active only with structure and detiling. Black retains original material; white permits safe donor variation. Missing mask defaults black. Overrides the blend selector with coherent common weights; off by default. |
| `structure_guard_in_albedo_alpha` | Read the linear guard from albedo alpha instead of the separate mask; requires matching mask/albedo dimensions and safe RGBA import settings. Off by default. |
| `brick_individual_enabled`, `brick_individual_map` | Optional prepared brick palette mode with aligned original PBR; requires detiling, structure and guard. Off by default. |
| `brick_individual_tiles_per_axis` | Atlas source-tile count; defaults to 4. UVs, gradients and integer offsets use this count. Each tile retains native source resolution. |
| `brick_individual_stochastic` | Mix source-aligned color variants; defaults true. False directly repeats the finite atlas as a comparison. |
| `structure_period` | Source-UV X/Y translation steps; zero locks that coordinate. Default `(1,1)` gives no meaningful variation with zero stagger. |
| `structure_stagger` | Fraction of the X step added per Y step, e.g. `0.5` for a matching running-bond lattice. Default zero. |
| `blend_contrast` | Adjust the color and roughness weight curve (and normals in shared-weight mode); 0.5 is neutral. Higher values may reveal the lattice. |
| `paper_blend` | Enable separate luminance-weighted color/roughness and slope-weighted normal blending. Off by default; ignored when `coherent_blend` is enabled. |
| `coherent_blend` | Use one content-guided mixture for color, normal slopes, and roughness. Off by default; takes precedence over `paper_blend`. |
| `coherent_filter` | Relax coherent blend sharpness and content guidance as footprint grows. On by default; used only in coherent mode. This heuristic can soften texture. |
| `paper_falloff` | Controls content influence in paper and coherent modes; default 0.6. |
| `normal_blend_contrast` | Weight curve for normal samples in paper mode; 0.5 is neutral. Ignored in coherent mode. |
| `use_roughness_map`, `roughness_map` | Enable and assign a matching roughness texture. |
| `detile_blend_power` | Sharpen the blend between offset samples. |
| `detile_detrend` | Adjust color tone normalization; zero disables it. |
| `detile_detrend_lod` | Normalization blur level relative to a 512-pixel map; scales with texture dimensions. |
| `normal_strength`, `roughness` | Surface appearance controls. In coherent mode `normal_strength` also controls the normal cue in the shared mixture. |

## How it works and when to use it

The shader samples three randomly offset copies of a repeatable texture on a triangular lattice, blends them, and projects the result along three world axes. The material maps share cell offsets and rotations. In the default mode they also share geometric blend weights; optional paper-inspired weighting calculates weights separately for color, roughness, and normals, which can shift how corresponding features blend. Optional rotation transforms texture derivatives for mip selection and rotates sampled normal components back into projection space. Rotation is off by default; directional textures may work better without it. `blend_contrast` changes the blend-weight curve to retain more definition, but high values can expose the grid; it does not guarantee contrast preservation. Optional tone normalization can reduce broad patches but can change color or suppress features; it defaults to off. World-space projection means moving or rotating an object moves it through the texture. In paper-inspired mode, color and roughness weights use sample luminance; normal samples are converted to slopes, weighted by slope magnitude, and blended before normal reconstruction. The implementation reconstructs normal Z from XY and caps grazing slopes for stability. This adapts the paper to the triplanar material; it is not a complete or exact reproduction. Normal mapping remains an approximation based on the geometric normal and sampled tangent components, not a general substitute for a mesh's tangent-space material.

Large organic surfaces are a useful starting point. Strong, recognizable features can still repeat or form patches. Triplanar projection, multiple texture samples, and normalization add GPU work; legacy detiling keeps sampling its donors, while protected and palette routes can skip donor work in their exact or coarse fallback cases. Source-level counts are not runtime cost estimates. See the [benchmark and its limitations](benchmarks/README.md), and profile on your target hardware.

## Research and experiments

The [experiments](experiments/) notes describe later texture-blending research and an exploratory two-band prototype that did not demonstrate a clear improvement on the current material set. The supported shader retains the existing modes and adds an [optional project-specific synthesis](docs/coherent/README.md), with no research-novelty claim.

## Project checks

After importing assets, run `godot --headless --path . --script res://tests/smoke.gd` to check scene loading, texture binding, and the sampling toggle. On a machine with a graphics display, `godot --path . --script res://tests/gpu_probe.gd` checks that a flat normal map leaves lighting unchanged at full rotation. Run `godot --path . --script res://tests/capture.gd` to regenerate the initial stills, or `godot --path . --script res://tests/material_gallery.gd` for the paired material and mesh gallery in `docs/gallery/`. Run `godot --path . --script res://tests/variety_gallery.gd` to regenerate the six-material stress test in `docs/variety/`. Run the [coherent GPU fixtures and capture scripts](docs/coherent/README.md#reproduce) for the new mode. These checks do not establish correctness for every normal map or renderer.

## Credits and license

Adapted from the author's `chain-racing` material and cliff study. Based on Morten S. Mikkelsen's [Practical Real-Time Hex-Tiling](https://jcgt.org/published/0011/03/05/), JCGT, 2022. This adaptation includes optional cell rotation, blend-weight curves, and a paper-inspired mode for luminance- and slope-based weighting; it also offers a separate multiplicative color normalization. It is not a verbatim implementation of every technique in the paper. See [third-party notices](addons/hex_detile/THIRD_PARTY_NOTICES.md) for the original Godot reference and its license.

Code and documentation: [MIT License](LICENSE). The example texture sets are [Rocks Ground 04](https://polyhaven.com/a/rocks_ground_04) and [Sandstone Cracks](https://polyhaven.com/a/sandstone_cracks), by Rob Tuytel / Poly Haven, plus [Rock Boulder Cracked](https://polyhaven.com/a/rock_boulder_cracked), photography by Dimitrios Savva and processing by Dario Barresi / Poly Haven. All are [CC0](https://polyhaven.com/license). The sandstone and boulder maps were resized to 1024 pixels for this demo. Screenshots depict those textures. Godot is distributed separately under its own license.

Additional gallery maps are from Poly Haven under [CC0](https://polyhaven.com/license): [Brick 4](https://polyhaven.com/a/brick_4) and [Denim Fabric](https://polyhaven.com/a/denim_fabric) by Rob Tuytel; [Dark Wooden Planks](https://polyhaven.com/a/dark_wooden_planks) and [Checkered Pavement Tiles](https://polyhaven.com/a/checkered_pavement_tiles) by Amal Kumar; [Grass Ground](https://polyhaven.com/a/grass_ground) by Charlotte Baglioni; and [Cobblestone 01](https://polyhaven.com/a/cobblestone_01) by Rob Tuytel. The 1K maps and their source URLs and checksums are listed in [SOURCES.json](assets/gallery/SOURCES.json).

The eight-material expansion adds [Snow 02](https://polyhaven.com/a/snow_02), [Brown Mud 02](https://polyhaven.com/a/brown_mud_02), [Brown Leather](https://polyhaven.com/a/brown_leather), and [Mossy Rock](https://polyhaven.com/a/mossy_rock) by Rob Tuytel; [Blue Plaster Wall](https://polyhaven.com/a/blue_plaster_wall) by Dimitrios Savva; [Sand 03](https://polyhaven.com/a/sand_03) by Charlotte Baglioni; and [Rubber Tiles](https://polyhaven.com/a/rubber_tiles) and [Terrazzo Tiles](https://polyhaven.com/a/terrazzo_tiles) by Amal Kumar, all Poly Haven / CC0. Matching original 1K albedo, OpenGL normal, and roughness maps have verified download hashes in [SOURCES.json](assets/gallery/SOURCES.json); [preparation notes](assets/gallery/EXPANSION.md) explain the selection and imports.

The prepared-source extension adds [Red Brick](https://polyhaven.com/a/red_brick) and [Large Red Bricks](https://polyhaven.com/a/large_red_bricks), both by Rob Tuytel / Poly Haven under CC0. Their native PBR/height downloads, authored mask exclusions and failed palette qualification results are documented in [source provenance](docs/brick_atlas_release/materials/SOURCES.md). They remain controlled authoring examples rather than fully qualified palette presets.
