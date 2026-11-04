# Balanced 2 × 2 palette retry

The initial 2 × 2 packing retained source resolution and the full source palette, but each source brick had only four randomly chosen variants. Its per-source mean color remained more biased than the 16-variant 4 × 4 packing. The initial assets and failed GPU quality evidence remain unchanged.

This single packing revision changes palette assignments only. It starts from the same seed-specific global shuffle and makes deterministic swaps between actual toroidal brick components. The objective reduces the squared deviation of each source brick's four-variant mean RGB from the global palette mean. RGB is whitened by the palette covariance, regularized with 10% of the mean channel variance; this gives chromatic directions influence without amplifying a nearly degenerate color axis excessively. A duplicate-choice penalty encourages four distinct palette colors for each source brick. Each seed evaluates 250,000 proposed pairs and accepts only objective-reducing swaps.

Swapping preserves the exact global palette counts: all 83 source colors appear four times. Both generated seeds have four distinct choices per source brick. The actual generated core-color mean variance across source IDs falls from 0.00166137 to 0.0000350591 for seed 0 and from 0.00134348 to 0.0000293825 for seed 7 (summed linear RGB variance). These are packing statistics, not a rendered-quality verdict. [cpu-audit.json](cpu-audit.json) records the measured output statistics; each seed's assignment JSON records the whitened objective before/after and accepted swap count.

Segmentation, local RGB base normalization, mask feather, source coordinates, source palette, normal/roughness assets, and highlight handling remain the same as the [4 × 4 recipe](../../individual_brick/PREPROCESSING.md). Both revised 2048² assets retain all 4,194,304 alpha bytes and all 1,700,480 protected RGBA pixels exactly. No source pixel is resized. A bound RGBA8 atlas with full mipmaps uses 22,369,620 bytes, approximately 21.33 MiB. Direct sampling still has a finite two-source repeat; stochastic sampling requires its separate filtering and quality evaluation.

```sh
python3 scripts/prepare_individual_brick_atlas.py \
  --tiles 2 --balance-palette \
  --name brick_4_individual_atlas_2x2_balanced \
  --evidence docs/brick_atlas_release/brick4_2x2_balanced
```
