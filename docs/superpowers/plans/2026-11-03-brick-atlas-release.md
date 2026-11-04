# Brick Atlas Release Candidate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce atlas storage while retaining quality, extend tested brick coverage, and package the supported result.
**Architecture:** Configurable source-tile count with immutable comparison assets, data-driven supported presets, aligned source PBR and filtered stochastic palette sampling.
**Tech Stack:** Godot shader/GDScript; Python preprocessing and image analysis.
**Spec:** `docs/superpowers/specs/2026-11-03-brick-atlas-release.md`

## Global Constraints

- Branch `codex/brick-atlas-release`, base0f5322a; no version/commit/merge/publication until root final review.
- `brick_individual_tiles_per_axis=4` preserves compatibility; new 2×2 assets retain native 1024² source tiles.
- Original assets, guard/PBR semantics, squared weights and field grid remain unchanged.
- CPU generation belongs to asset worker; all GPU work belongs exclusively to test worker.
- Report memory estimates, measured rendering intervals and GPU timings as distinct quantities.

## Review Focus

- Integer source phase and gradient scaling remain correct at both atlas sizes.
- Smaller variant sets must not recreate colored source patches or flatten brick palettes.
- Authored masks and matching source PBR are required for additional materials.
- Corners/curves retain expected triplanar limits without doubled mortar claims.
- Defaults, generic materials, UI restoration, package contents and provenance stay coherent.

### Step 1: Smaller native-resolution atlas

- [x] Create branch and record RED for absent tile-count uniform; freeze accepted 4×4 shader/helper/assets.
- [x] Asset worker creates `brick_4_individual_atlas_2x2_seed0/7.png` with exact protected RGB/alpha and separate import/provenance.
- [x] Parameterize only atlas addressing/offset count in `addons/hex_detile/hex_detile.gdshader`; leave demo at 4×4 until gate.
- [x] Hand frozen source to tester for off/4×4 compatibility and 2×2 quality checks.

### Step 2: Memory and rendering comparison

- [x] Compare v0.7.0, accepted 4×4 and new 2×2 using matched repetition/palette/mortar/motion criteria.
- [x] Record theoretical texel storage and available measured memory evidence with correct scope.
- [x] Measure matched CPU synchronous render-call intervals with rounds/ranges; no isolated GPU claim without valid samples.
- [x] Root selects the retained atlas size based on all evidence; switch demo only after acceptance.

### Step 3: Materials and meshes, after quality gate

- [x] Asset worker prepares at least two additional actual brick sources, source-specific masks, aligned PBR, atlases and provenance.
- [x] Add data-driven supported brick descriptors and append material choices; preserve existing indices/defaults.
- [x] Evaluate original/new on walls, corners and curved triplanar geometry, including protected mortar and motion.
- [x] Enable only supported tested presets; explicitly document authored-mask requirements and remaining layout repetition.

### Step 4: Package the successful result

- [x] Update addon/root/user documentation, settings, comparison imagery and preprocessing reproduction.
- [x] Keep prior macro findings experimental and clearly distinct from the retained supported mode.
- [x] Root reviews final implementation, all quality/benchmark/material evidence and package scope.
- [x] With root approval, prepare version/archive, verify contents/UIDs/source bytes/CRC; publication actions require root final decision.

Ruling: the first randomly assigned 2×2 candidate passed the older absolute distant criteria only narrowly and failed the predeclared five-percentage-point noninferiority gate against accepted 4×4. Keep its assets/evidence and the 4×4 demo unchanged. Root authorized one packing-only retry: deterministic palette swaps reduce per-source-brick mean bias while preserving global counts, native RGB/alpha constraints, shader and criteria. Distinct balanced asset names prevent overwriting the failed candidate. Timing waits until heavy CPU generation is idle.

Ruling: balanced 2×2 improves all color measures but still fails the strict gate at intermediate view seed7 luminance correlation (+0.147 versus the allowed +0.05 over 4×4). No waiver or further 2×2 tuning. Root authorized one final balanced 3×3 size trial (~48 MiB theoretical RGBA8 mip texels) under unchanged shader/criteria; if it fails, retain 4×4 and describe compact 2×2 only as a qualified tradeoff. Root also approved the authored Red Brick/Large Red Bricks masks for controlled evaluation, including documented exclusions and pale faces.

Ruling: final balanced 3×3 also fails the same strict intermediate seed7 luminance allowance. Retain accepted Brick 4 4×4 as quality default; no more size trials. Balanced 2×2 remains a documented explicit lower-memory tradeoff, not equivalent; no user-facing 3×3 preset. Red Brick and Large Red Bricks prepared 4×4 assets are added at stable indices17/18 with `supported=false` until controlled wall/corner/curved evaluation and root review. Existing indices0–16 and the Brick 4-only macro experiment remain isolated.

Outcome: accepted Brick 4 retains 4×4; no smaller candidate passed every strict quality condition. Rendering cost improves close-wall/sphere but worsens at the distant wall in the scoped CPU-call test. Added Red Brick/Large Red Bricks are controlled authoring examples, remain `supported=false`, and are not promoted after their full-gate failures. The interactive mesh selector, scrolling, visible source synchronization and source-specific state restoration pass visible/default/small-window checks. Thirteen fresh regressions pass. Root authorized v0.8.0 candidate preparation and requires fresh extracted-addon checks before final publication review. Historical measurements/failed conclusions remain; current-status notes distinguish packaged accepted mode from experimental records.

Final handoff: root reviewed the complete result and independently verified fresh extracted-addon import/runtime PASS, ten source-byte matches, generic tile-count controls and thirteen regressions. Version 0.8.0 archive SHA256 is recorded in package.json. Root gave full commit/publication authorization after independent package review. No further renderer or quality changes were made.
