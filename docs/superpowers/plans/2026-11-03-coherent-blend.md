# Coherent Material Blending Implementation Plan

> Execute inline using superpowers:executing-plans; verify before completion.

**Goal:** Add and evaluate an optional material-coherent, footprint-aware detiling mode.
**Architecture:** Preserve legacy paths; add a bundled PBR sampling include and shared weight helper. Integrate with the demo's blend selector and document reproducible results.
**Tech Stack:** Godot 4 shader language, GDScript GPU tests, Python/Pillow for capture contact sheets.
**Spec:** ../specs/2026-11-03-coherent-blend-design.md

## Global constraints

Existing defaults unchanged; no additional texture reads; Godot Compatibility is the tested renderer; observations do not establish research novelty or general quality superiority.

## Review focus

Zero-support triangle edges, flat normals, disabled roughness/normal input, minified projections and old materials with no new parameters. Tests exercise these in tasks 1 and 2.

## Task 1: Coherent sampling

- [x] Add GPU tests using production helper functions and deterministic fixtures; run and observe failure before implementation.
- [x] Add shared weight and bundled sampler helpers in addons/hex_detile/coherent_blend.gdshaderinc; integrate opt-in uniforms and branch into hex_detile.gdshader.
- [x] Run new GPU checks plus existing smoke and gpu_probe scripts. Confirm old modes remain intact.

## Task 2: Evaluate and present

- [x] Expose Shared / Paper / Coherent choices and footprint relaxation in demo.gd.
- [x] Add reproducible seventeen-material, multi-view capture script and mode comparison benchmark.
- [x] Inspect captures, record results and limits, add README entry, addon instructions and detailed docs/coherent/README.md.
- [ ] Complete final full-diff review and validation, then commit and push only after coordinator review. Publication remains pending.

## Execution notes

The user expanded the evaluation from nine to seventeen public scanned-material sets and requested lower-cost agents for code, assets, and tests, with an Astra coordinator integrating and reviewing. Twenty capture cases include the seventeen materials and three alternate views. Generated-material experiments remain separately reviewed and do not change this public count.

The initial GPU probe failed before implementation with `FAIL: coherent material mode is missing` (exit 1). An added maximum-power/contrast fixture later exposed a collapsed equal mixture; normalization was fixed before the check passed. A nonflat correlated fixture also rejects deliberate independent-normal-weight and wrong-rotation mutations. These targeted results support the checked implementation steps; final review, release validation, commit, and push are separate pending work.
