# Publishing notes

Suggested GitHub repository name: `godot-hex-detiling`  
Description: Godot 4 shader and demo for reducing repeated textures with stochastic hex tiling and triplanar projection.  
Suggested topics: `godot`, `godot4`, `godot-shader`, `shader`, `texture-tiling`, `triplanar`, `game-development`, `procedural-textures`.

## Asset Store listing draft

**Title:** Hex Detiling Shader for Godot  
**Type:** Add-on / shader asset  
**License:** MIT for code; example textures CC0  
**Godot version:** 4.7.2 tested; do not claim a lower minimum until tested.

Reduce obvious repetition on large rock, dirt, and other organic surfaces. This shader combines stochastic offset sampling with world-space triplanar projection and uses shared transforms for albedo, normal, and optional roughness maps. Includes two texture sets, a comparison demo, and an optional editor dock. Adjust the scale, rotation, and blend controls to fit your material. Additional texture samples have a GPU cost; benchmark in your own scene.

Use the comparison GIF and paired screenshots in `docs/` for the listing. Choose a public repository URL, release version and stable archive, verify the license and credits, and check the current [Godot Asset Store submission guidelines](https://docs.godotengine.org/en/stable/community/asset_store/submitting_to_asset_store.html) before submitting. A listing has not been created.

The store requires an **AI usage disclosure** when AI was used. This project and its documentation were prepared with Codex assistance; accurately describe the extent of that assistance in the listing. The store currently supports free assets; check its current terms and pricing options at submission time. The project owner should confirm the copyright holder name and license before release.

`dist/hex-detile-addon.zip` contains the shader add-on and its license notices. The full project and CC0 texture examples remain available in the repository. `docs/store-thumbnail.png` is a draft listing icon. The comparison GIF can be regenerated after the stills with `python3 tests/make_media.py` (requires Pillow).
