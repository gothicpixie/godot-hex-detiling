# Mortar Guard Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Reduce guarded texture sampling without changing protected material appearance.

**Architecture:** Packed alpha shares reference and donor albedo fetches; exact source-only cases return before donor work. The demo opts into packing while the generic addon retains separate-mask compatibility.

**Tech Stack:** Godot 4 shaders/GDScript, Python packing verification, Compatibility renderer.

**Spec:** `docs/superpowers/specs/2026-11-03-guard-optimization-design.md`

## Global Constraints

- `structure_guard_in_albedo_alpha=false` by default; generic separate mask API remains supported.
- Fade remains two to eight mask texels; packed alpha requires matching dimensions.
- No epsilon early return or per-donor normal skip; protected source color remains raw.
- No GPU run from implementation worker; benchmark/test worker owns GPU execution.
- No commit or release before coordinator approval.

## Review Focus

- Missing separate mask preserves source material.
- Packed alpha remains linear while RGB is decoded as source color.
- Source-only normal reconstructs and normalizes the same slope as the original mixture.
- Detrending and optional roughness preserve the common mixture.
- Material/structure/detiling transitions restore original albedo and packing flag while retaining guard preference.

### Task 1: Packed asset

**Files:** `scripts/pack_guard_albedo.py`, `assets/gallery/brick_4_albedo_guard.png` and `.import`, `docs/guard_optimization/PACKING.md`, `packed-albedo.json`.
**Interfaces:** Produces `res://assets/gallery/brick_4_albedo_guard.png` with matching RGB and alpha source bytes; asset worker owns provenance and CPU checks.

- [x] Verify packed RGB and alpha against decoded source arrays, including dimensions and import settings.
- [x] Import once under benchmark worker ownership and verify runtime sampled equivalence.

### Task 2: Shader and demo

**Files:** `addons/hex_detile/hex_detile.gdshader`, `coherent_blend.gdshaderinc`, `demo.gd`; test worker owns tests.
**Interfaces:** Adds bool uniform `structure_guard_in_albedo_alpha=false`; consumes packed asset path above. Benchmark ablations may disable a bracketed source-only return in a generated test shader without adding a production toggle.

- [x] Test worker demonstrates RED for absent packed uniform/demo activation before implementation.
- [x] Add packed reference/donor mask extraction, explicit pre-call projection gradients and exact source-only return before donor reads.
- [x] Bind packed texture only when Brick 4 guard, structure and detiling are active; restore original texture otherwise.
- [x] Run headless UI/material checks and test worker's matched GPU probes, including transition, motion, roughness, detrending and legacy modes.

### Task 3: Evidence and documentation

**Files:** `README.md`, `addons/hex_detile/README.md`, `docs/brick_guard/README.md`, `docs/guard_optimization/` and benchmark results owned by test worker.
**Interfaces:** Consumes four-way benchmark and equivalence results.

- [x] Measure frozen v0.6.0, packed-only, early-only and both with identical settings.
- [x] Keep only justified complexity; state source-level worst-case read counts separately from measured whole-frame intervals.
- [x] Update docs with generic packing requirements and linked validation evidence.
- [x] Coordinator reviews diff and validation before committing/publishing.

Execution record: RED was observed before production changes. The GPU worker validated packed imports, channels, 48 spatial comparisons, 384 final matched motion frames including the corrected fade-crossing approach, and eight regression scripts. All passed within the declared RGBA8 tolerances. Four-way final render-call measurements supported keeping both changes. Version 0.7.0 archive preparation verified ten files, three UID sidecars, CRCs and source bytes; see `docs/guard_optimization/package.json`. Coordinator approved final publication after reviewing the corrected fade-crossing motion, regressions and benchmark evidence.
