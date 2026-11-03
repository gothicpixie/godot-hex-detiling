# Actual-brick palette atlas preprocessing

This experiment changes color identities of actual authored brick interiors. It does not infer an ideal running-bond grid or overlay a macro noise field. `brick_4_individual_atlas_seed0.png` and `brick_4_individual_atlas_seed7.png` are separate 4096 × 4096 RGBA copies covering four original 1024-pixel repeats on each axis. No source pixels are resized, warped, or moved. Alpha repeats the original mask exactly. Every pixel with alpha zero retains the exact original RGB bytes. Source albedo, packed albedo, normal, roughness and mask remain unchanged.

The source is **Brick 4 by Rob Tuytel / Poly Haven, CC0**. Original URLs/checksums are in [SOURCES.json](../../assets/gallery/SOURCES.json); the derived mask's [provenance](../brick_guard/source-mask.json) remains applicable. The new atlas/provenance also carry CC0.

## Segmentation and seams

Four-neighbor connected components of `alpha > 0` identify actual irregular interiors. Components touching opposite image edges are unioned on a torus. The original image has 84 such regions: 83 brick interiors and one isolated single pixel. The tiny island remains unchanged. [Source annotation](source-segmentation.png) overlays region IDs and areas; [source-region-ids.png](source-region-ids.png) stores exact integer labels, with background zero.

Segmentation runs again on the full 4 × 4 tiled mask, then unions the outer atlas edges. This gives 1,328 actual brick interiors and 16 unchanged one-pixel islands. It handles both internal source-cell boundaries and outer atlas wrapping. A brick crossing a boundary receives one connected-region assignment, rather than independently assigning colors to its clipped pieces. [atlas-region-ids.png](atlas-region-ids.png) contains the full-resolution 16-bit labels. Equal nonzero labels across an outer seam establish shared component identity; this does not assert the original source boundary RGB was seamless.

## Color reassignment

Each of the 83 source bricks contributes a plausible palette color: the median linear RGB of its fully eligible (`alpha=255`) core. Each atlas receives every palette color exactly 16 times, shuffled independently with seed 0 or 7 across the 1,328 actual atlas bricks. Repeated copies of one source brick therefore usually receive different colors. This is balanced palette frequency, not equal pixel-weighted color area or a guarantee of identical overall brightness.

The script estimates a smooth linear RGB base inside each individual source brick using alpha-normalized Gaussian filtering at sigma 12 pixels, without borrowing mortar or neighboring-brick colors. The correction base combines 80% of this local field with 20% of the brick's core median. Source boundary-crossing bricks are unwrapped before filtering. A per-channel multiplicative ratio changes this base toward the assigned palette color; the original alpha feathers that ratio back to identity at protected pixels. This neutralizes broad hue and luminance identities as well as their mean color. Fine multiplicative residuals remain at their original coordinates; they are not analytically identical after 8-bit rounding or sparse highlight gamut handling.

For rare original bright specks that would exceed linear RGB 1, a common RGB scale brings their maximum channel to 1 while retaining RGB ratios. This affects 237 atlas pixels (0.00141%) in seed 0 and 151 (0.00090%) in seed 7. No independent-channel clipping or nonfinite RGB is allowed. Protected pixels bypass every correction. The feathered boundary can still reveal original protected rim colors against a strongly recolored interior; native images and engine captures must evaluate whether this looks like a colored halo. Exact protected RGB alone does not establish natural appearance.

The [whole-atlas overview](atlas-overview-seed0.jpg) compares the repeated source with reassigned colors. [Native seed 0](source-native-seed0.png) and [seed 7](source-native-seed7.png) compare identical pixel coordinates across an internal source-cell boundary. Preview thumbnails are resized for display; the actual assets retain 4096² pixels.

## Reproduction and bounds

```sh
python3 scripts/prepare_individual_brick_atlas.py --tiles 4 --seeds 0 7
```

Requires Pillow, NumPy and SciPy. [atlas-provenance.json](atlas-provenance.json) records parameters, source/palette data, library versions and output hashes. [Seed 0 assignments](atlas-seed0.json) and [seed 7 assignments](atlas-seed7.json) record every component's source identity, chosen palette, core color, and boundary membership. CPU generation verifies alpha equality across all 16,777,216 atlas pixels, exact source RGB for all 6,801,920 protected pixels, finite/in-gamut output, balanced palette frequency, component seam identity, and a lossless saved-PNG round trip.

The accompanying import settings retain lossless RGBA, mipmaps, identity channel mapping, no alpha-border repair or premultiplication, and no automatic normal/roughness/3D compression processing. One 4096² RGBA8 atlas with full mipmaps occupies approximately **85.3 MiB** uncompressed; source and other PBR maps are additional. Only one atlas need be bound at runtime. The two seeds are evaluation variants.

The atlas has an exact finite period of **four source repeats**, or 10 m at 2.5 m source scale. Palette reassignment can weaken the old 2.5 m color pattern but cannot provide infinite nonrepeating appearance. Original mortar shapes, fine marks, and normal/roughness patterns retain their old source period. No quality or runtime performance improvement follows solely from these preprocessing checks.
