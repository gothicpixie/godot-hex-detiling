# Packed guard albedo

`assets/gallery/brick_4_albedo_guard.png` stores the decoded RGB bytes from the existing `brick_4_albedo.jpg` and the unchanged linear `brick_4_interior_mask.png` bytes in alpha. The original files remain unmodified. Alpha is guard data, including at zero; RGB at those pixels still contains the original mortar color. Do not erase transparent RGB or premultiply this image in an editor.

The albedo is **Brick 4** by **Rob Tuytel / Poly Haven**, licensed [CC0](https://polyhaven.com/license), with upstream URLs and checksums in [SOURCES.json](../../assets/gallery/SOURCES.json). The mask derives from the matching CC0 displacement; its [provenance](../brick_guard/source-mask.json) and [algorithm](../brick_guard/source-mask.md) remain applicable. Packing does not regenerate the mask or change its protected band.

From the repository root, using Python with Pillow:

```sh
python3 scripts/pack_guard_albedo.py \
  assets/gallery/brick_4_albedo.jpg \
  assets/gallery/brick_4_interior_mask.png \
  assets/gallery/brick_4_albedo_guard.png \
  --provenance docs/guard_optimization/packed-albedo.json
```

The generic script requires equal dimensions and an 8-bit `L` mask and rejects an output path equal to either input. It never resamples. It verifies every decoded output RGB and alpha byte, including RGB where alpha is zero, and checks that input file hashes remain unchanged. [packed-albedo.json](packed-albedo.json) records the input/output hashes, decoded channel hashes, size, and Pillow version. PNG byte identity across different encoder versions is not guaranteed; decoded channel identity is the required invariant.

The accompanying Godot import uses lossless compression (`compress/mode=0`), identity channel mapping, mipmaps, no size limit, no normal/roughness processing, disabled automatic 3D compression, `process/fix_alpha_border=false`, and `process/premult_alpha=false`. Fix Alpha Border intentionally alters color around transparent pixels, and premultiplication alters RGB by alpha, so both would damage this packed data. See the [official import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html#process-fix-alpha-border). Godot's [lossless WebP packer](https://github.com/godotengine/godot/blob/4.6/modules/webp/webp_common.cpp#L75-L78) sets `config.exact=1`, preserving color under zero alpha; the [texture importer](https://github.com/godotengine/godot/blob/4.6/editor/import/resource_importer_texture.cpp#L250-L272) can also use PNG lossless storage. The generated PNG itself does not rely on WebP.

The shader's color sampler uses `source_color` for RGB. Alpha remains a linear normalized guard value. The shader must not write spatial `ALPHA`, because this data channel does not describe material transparency. Packing verification establishes source byte equality only; Godot import, mip-level sampling, rendering equivalence, and performance require the separate engine validation.
