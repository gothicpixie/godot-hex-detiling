# Additional CC0 material sets

Eight Poly Haven sets extend the demo from nine to seventeen materials. The original nine retain their indices. Availability, names, authors, download URLs, byte sizes, and MD5 checksums were checked against the primary Poly Haven public API on 2026-11-03. Poly Haven publishes all these assets under [CC0](https://polyhaven.com/license), including redistribution. Only asset texture maps are included, not Poly Haven preview renders or website content.

| Demo index | Material and source | Author | Surface variation |
| --- | --- | --- | --- |
| 9 | [Snow 02](https://polyhaven.com/a/snow_02) | Rob Tuytel / Poly Haven | Powdery snow and subtle ridges |
| 10 | [Brown Mud 02](https://polyhaven.com/a/brown_mud_02) | Rob Tuytel / Poly Haven | Earth with footprints and wet soil |
| 11 | [Blue Plaster Wall](https://polyhaven.com/a/blue_plaster_wall) | Dimitrios Savva / Poly Haven | Blue painted, cracked plaster |
| 12 | [Brown Leather](https://polyhaven.com/a/brown_leather) | Rob Tuytel / Poly Haven | Matte, wrinkled upholstery leather |
| 13 | [Rubber Tiles](https://polyhaven.com/a/rubber_tiles) | Amal Kumar / Poly Haven | Smooth rubber flooring with square seams |
| 14 | [Sand 03](https://polyhaven.com/a/sand_03) | Charlotte Baglioni / Poly Haven | Granular beach sand |
| 15 | [Mossy Rock](https://polyhaven.com/a/mossy_rock) | Rob Tuytel / Poly Haven | Organic moss and lichen on rock |
| 16 | [Terrazzo Tiles](https://polyhaven.com/a/terrazzo_tiles) | Amal Kumar / Poly Haven | Speckled terrazzo flooring with tile boundaries |

The current Poly Haven texture catalog contained no cork asset. Rubber Tiles is a deliberately different dielectric substitute. Mossy Rock represents moss coverage on stone, rather than a standalone moss carpet. Sand 03 is a beach-sand material; its title is preserved rather than relabeling it as a fine-sand scan. Brown Mud 02 has wet-soil features, but this demo does not implement puddle depth, liquid layers, or separate wetness controls. Snow uses the same opaque dielectric shader as other materials; no subsurface snow shading is implied.

## Preparation and import

Each set consists of matching **Diffuse**, **nor_gl**, and **Rough** maps from the same asset's official **1K JPG** downloads. Local filenames use `_albedo.jpg`, `_normal.jpg`, and `_roughness.jpg`. Each file is 1024 × 1024 pixels. These are the original 1K JPEG bytes, with no recompression, downsampling, color adjustment, normal inversion, or invented map reconstruction. All 24 downloads were verified against both the MD5 and byte count returned by `https://api.polyhaven.com/files/<asset_id>` before writing the manifest.

The 24 files total **15,464,989 bytes** (about 14.75 MiB). The original 1K resolution provides a modest demo budget while retaining material variety. Every new texture has committed Godot `.import` metadata with `mipmaps/generate=true`; `process/normal_map_invert_y=false` preserves the source OpenGL normal convention. Import uses lossless texture storage (`compress/mode=0`) and retains normal RGB channels. The shader declares albedo as source color while sampling normals and roughness as data. No metalness map, height map, displacement, specular map, or translucency map is bound; these assets are used as dielectric examples.

The structured [SOURCES.json](SOURCES.json) preserves the existing schema (`asset`, `name`, `authors`, `source`, `license`, and per-map `url` / `md5` / `bytes`). Its first six records are unchanged, and these eight records are appended. Demo `TEXTURE_NAMES` parallels `TEXTURE_SETS`; the selector is populated from the names so additions remain synchronized.

These are source and preparation notes, not a claim that any blend mode improves every surface. Rendered comparisons and automated checks are documented separately.
