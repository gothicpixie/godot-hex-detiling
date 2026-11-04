# Brick atlas release validation

The accepted Brick 4 **4×4 atlas remains the qualified configuration**. Smaller atlas candidates and the two added sources were tested rather than assumed safe: each misses part of its predeclared appearance gate, so none silently expands the qualified set. The addon still provides useful color variation with the previously validated 4×4 result; joint layout/fine weathering continue to repeat, and curved triplanar projection limits remain.

## Evidence and decisions

- **Stage 1 — size/cost:** [STAGE1.md](STAGE1.md). Original 2×2, one balanced 2×2 retry, and final balanced 3×3 all fail complete noninferiority. Their measured texture storage falls, but intermediate seed 7 luminance repetition worsens. Accepted 4×4 retained; failed-arm metrics and images remain. Current dimension default 4 is pixel-identical to the frozen accepted shader, and feature OFF matches v0.7.0 exactly.
- **Controlled timing/memory:** 27 round-arms, 6,480 measured actual draws; synchronous render-call timing only, GPU timer unavailable. Fresh isolated RenderingServer texture-accounting increments match 5.33 MiB original, 85.33 MiB 4×4, 21.33 MiB 2×2 and 48 MiB 3×3. These are not physical VRAM-residency or FPS claims. Exact settings/ranges/limitations are in Stage 1 and the JSON evidence.
- **Stage 2 — materials/meshes:** [STAGE2.md](STAGE2.md). Both added sources improve chromatic repetition, but Red Brick fails luminance correlation and narrowly palette variance; Large Red Bricks fails luminance correlation. They remain unsupported controlled examples. Native wall/corner/cylinder comparisons and two matched orbit GIFs show the tested behavior. Protected rendered RGB ≤1 byte and material channels exactly equal in the sampled protected regions; global brick-course continuity is not claimed.

## Final application checks

`regressions.json`: 13 final relevant scripts pass, including legacy smoke/GPU/coherent/structure/guard contracts, individual/macro controls, atlas default 4, prepared-source gating/restoration and visible source-selector synchronization. The new material-smoke initially assumed unsupported source 0 would preserve its source-pattern toggle; the harness now explicitly reenables that established toggle before checking remembered individual preference. Only the affected smoke was rerun; its initial log is retained.

`ui-checks.json`: final visible 1280×720 and 800×600 controls stay inside the viewport, and every active focusable control remains reachable through the scroll panel. Source selection and the rendered material agree. Release-facing top/bottom captures use Brick 4/Wall. Terrain, Wall, Box/corner and Cylinder switch correctly and the three explicit preview meshes have valid camera framing. Unused contrast/filter/blend controls are disabled in individual mode, and unsupported prepared examples explain their unavailable variation control.

Images: `ui-1280-top.png`, `ui-800-top.png`, their bottom-scroll counterparts, and `ui-mesh-0.png` through `ui-mesh-3.png`. These are actual rendered application views, not mockups.

## Fresh archive check

The final addon-only v0.8.0 ZIP passed installation and runtime checks in a newly created project, without repository assets or cached imports. SHA256: `e64b771cfb2d5f738baf27155265d73c6730dbea3714b1aae0340a7938c37406`. It contains 10 addon files, including 3 UIDs; CRC passed and every extracted file matches the final workspace bytes.

The plugin imported with no errors. A procedural-texture GPU smoke exercised feature OFF, compiled default N=4, explicit N=4 and generic N=2 addressing. Default 4 versus explicit 4 differs by 0 bytes; enabled 4/2 modes differ from OFF by up to 39/26 bytes respectively, confirming the feature paths actually rendered. Runtime/import exit codes are 0 with no shader/script errors. These installation checks do not claim that the rejected compact photographic atlases meet the quality gate.

Evidence: `fresh-package-checks.json`, `fresh-package-import.log`, `fresh-package-runtime.log` and `fresh-package-smoke.png`. The archive is addon-only; the prepared gallery/demo remains in the repository. Reproduction: `python3 tests/atlas_release_extract_smoke.py dist/hex-detile-addon.zip`.
