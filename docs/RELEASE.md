# Publishing notes

Suggested GitHub repository name: `godot-hex-detiling`  
Description: Godot 4 shader and demo for reducing repeated textures with stochastic hex tiling and triplanar projection.  
Suggested topics: `godot`, `godot4`, `godot-shader`, `shader`, `texture-tiling`, `triplanar`, `game-development`, `procedural-textures`.

## Asset Store listing draft

**Title:** Hex Detiling Shader for Godot  
**Type:** Add-on / shader asset  
**License:** MIT for code; example textures CC0  
**Godot version:** 4.7.2 tested; do not claim a lower minimum until tested.

Reduce obvious repetition on large rock, dirt, and other organic surfaces. This shader combines stochastic offset sampling with world-space triplanar projection and uses shared transforms for albedo, normal, and optional roughness maps. The repository includes seventeen CC0 texture sets, a comparison demo, and an optional editor dock. The add-on archive contains code and notices; texture examples are in the full repository. An optional coherent mode shares a content-guided mixture across albedo, normal slopes, and roughness, with heuristic footprint relaxation. Shared geometric weighting remains the default. An experimental structure-aware option constrains translations to a supplied source lattice and locks rotation. Scanned layouts can still misalign, and triplanar corners do not gain global architectural continuity. Differences can be subtle. Adjust the scale, rotation, and blend controls to fit your material. Additional texture samples have a GPU cost; benchmark in your own scene.

Use the comparison GIF and paired screenshots in `docs/` for the listing. Choose a public repository URL, release version and stable archive, verify the license and credits, and check the current [Godot Asset Store submission guidelines](https://docs.godotengine.org/en/stable/community/asset_store/submitting_to_asset_store.html) before submitting. A listing has not been created.

The store requires an **AI usage disclosure** when AI was used. This project, shader extension, implementation tests, captures, packaging, and documentation were prepared with Codex assistance. The owner requested lower-cost agents for code, assets, and tests while an Astra coordinator handled integration and review. The seventeen public example materials are sourced Poly Haven CC0 maps, not AI-generated textures. Experimental generated-material work is not part of this public seventeen-material count or the add-on archive; its provenance and publication terms require separate review. Accurately disclose the assistance in the listing. The store currently supports free assets; check its current terms and pricing options at submission time. The project owner should confirm the copyright holder name and license before release.

`dist/hex-detile-addon.zip` contains the shader add-on and its license notices. The full project and CC0 texture examples remain available in the repository. `docs/store-thumbnail.png` is a draft listing icon. The comparison GIF can be regenerated after the stills with `python3 tests/make_media.py` (requires Pillow).

## Version 0.5.0 preparation

The add-on is version 0.5.0. This adds opt-in experimental structure-aware transforms: a supplied source-UV period and row stagger constrain seeded translations, and rotation is locked while enabled. Approximate demo presets retain checker grids and long wood seams more clearly than unconstrained offsets; brick joints can still double or soften, and exact corner continuity is not guaranteed. See [matched structure comparisons and fixtures](structure/README.md). `dist/hex-detile-addon.zip` must include `coherent_blend.gdshaderinc` next to the shader, plugin scripts/configuration, README, LICENSE, and THIRD_PARTY_NOTICES.md. Exclude `.godot`, caches, screenshots, and demo textures. The default remains shared geometric weights; both content-guided coherent blending and paper-inspired blending are opt-in. See [coherent-mode evidence](coherent/README.md) for fixtures, failure cases, contact sheets, and measured limits.

Preparation and archive verification do not publish a release. GitHub publication follows the owner's authorization and coordinator review; an Asset Store listing has not been created.
