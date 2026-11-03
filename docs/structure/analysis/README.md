# Source-pattern calibration

All nine albedo/normal/roughness JPGs for these three materials are 1024 × 1024. Presets below express translations in source texture UV units; they assume identity rotation and a shared translation for all maps. They are approximate symmetries of the dominant layout, not exact symmetries of the photographed surface.

| Material | Horizontal basis | Vertical/staggered basis | Suggested period + stagger |
| --- | --- | --- | --- |
| `brick_4` | `(2/15, 0)` | `(1/15, 1/14)` | period `(2/15, 1/14)`, stagger `0.5` |
| `dark_wooden_planks` | `(1/4, 0)` | locked | period `(1/4, 0)`, stagger `0` |
| `checkered_pavement_tiles` | `(1/5, 0)` | `(0, 1/5)` | period `(1/5, 1/5)`, stagger `0` |

Brick has about fourteen courses per texture, with a dominant horizontal brick pitch near 136–137 pixels. Roughness gradient profile autocorrelation peaks at 73 pixels vertically (0.707) and 136 pixels horizontally (0.405); additional vertical peaks at 146 and 221 pixels support the course interpretation. A running-bond course advance needs half a brick's horizontal shift. The source's varied brick lengths, repairs, and uneven mortar mean no global lattice aligns every joint. The preset is a reasonable approximate layout constraint, not exact preservation. Long multiples accumulate the source's irregularity; visual inspection of the final render remains necessary.

Wood grain and plank seams run horizontally. There are roughly nine boards but widths are unequal; a vertical lag of 114 pixels yields only 0.219 gradient-profile autocorrelation. Keep y locked. Quarter-texture horizontal steps change grain and board surface detail while retaining long horizontal seams. Board end joints, small seam curvature, and broad lighting/color variation can still move.

Pavement has ten squares per axis, a 102.4-pixel square pitch. Roughness gradient-profile autocorrelation is about 0.95 at 102 pixels in both axes. A one-square axis shift swaps dark and light squares; require an even total square displacement. The suggested 0.2 axis steps preserve checker parity. An alternative tighter lattice is `(0.2,0)` and `(0.1,0.1)`, expressible as period `(0.2,0.1)` and stagger `0.5`. Individual squares have wavering edges and varied wear. The normal map is visually almost flat, while roughness and albedo contain the layout.

## Descriptive shift checks

`analyze_sources.py` uses CPU Pillow/NumPy and produces `source_stats.json`. It rolls source images with repeat addressing, extracts bright local roughness contrast (8-pixel Gaussian background, then 3-pixel Gaussian tolerance), and correlates that line proxy. The values describe these source images only; they do **not** measure shader output quality. Integer shifts approximate fractional UV lattice steps.

| Source | Shift in pixels | Roughness line correlation | Gray albedo correlation | Gray albedo mean absolute difference / 255 |
| --- | --- | --- | --- | --- |
| Brick | `(136,0)` | 0.656 | 0.338 | 24.78 |
| Brick | `(68,73)` | 0.603 | 0.257 | 26.41 |
| Brick | `(128,128)` | -0.116 | 0.002 | 32.07 |
| Wood | `(256,0)` | 0.660 | 0.195 | 8.84 |
| Wood | `(256,128)` | -0.127 | 0.000 | 10.00 |
| Pavement | `(205,0)` | 0.897 | 0.910 | 6.42 |
| Pavement | `(102,102)` | 0.888 | 0.906 | 6.56 |
| Pavement | `(102,0)` | 0.906 | -0.893 | 37.93 |
| Pavement | `(128,128)` | -0.081 | 0.253 | 18.50 |

The pavement one-square example shows why edge alignment alone is insufficient: its edges align but color parity reverses. The nonzero albedo differences for the proposed steps show that samples change; these are not trivial full-texture offsets. Repeating integer combinations can nevertheless wrap to the identity (four wood steps, five pavement steps). A shader that permits the zero offset can also select an unchanged sample. Those cases reduce variation rather than break geometry.

No GPU runs, shader modifications, texture modifications, or literature/novelty claims are part of this calibration.
