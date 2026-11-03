# Structure-aware Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional phase-constrained translation mode for structured materials.

**Architecture:** Branch in the existing shared transform helpers. Keep blend selection and texture reads unchanged; expose source-specific demo presets and general inspector uniforms.

**Tech Stack:** Godot spatial shader and GDScript.

**Spec:** `docs/superpowers/specs/2026-11-03-structure-aware-design.md`

## Global Constraints

Defaults remain unchanged. No additional texture reads. All material maps share the seeded transform. Preserve local ignored generation assets. No commit or push before coordinator review.

## Review Focus

- Zero period components lock the corresponding coordinate.
- Full-repeat steps yield no variation; checker parity requires two-square periods.
- Rotation is ignored only while structure mode is enabled.
- Source changes cannot silently retain an unrelated demo preset.
- Irregular sources and triplanar corners retain documented limitations.

### Task 1: Transform constraint and fixtures

**Files:** Modify `addons/hex_detile/hex_detile.gdshader`; test agent owns `tests/structure_*`.

**Interfaces:** `structure_enabled=false`, `structure_period=vec2(1)`, `structure_stagger=0`; integer shifts use `floor(detile_hash2(vec2(vertex))*9)-4`.

- [x] Test agent writes GPU fixtures for phase, parity, locked axis, seed determinism, rotation override, degenerate full repeats, and disabled regression.
- [x] Test agent records expected RED behavior before production changes.
- [x] Implement identity rotation and lattice shifts in shared helpers; preserve the existing disabled branches.
- [x] Test agent runs GPU checks and regression suite.

### Task 2: Demo, evidence, and packaging

**Files:** Modify `demo.gd`, `README.md`, `addons/hex_detile/README.md`, `docs/RELEASE.md`; create `docs/structure/README.md`; test agent owns captures.

**Interfaces:** Demo `set_structure(enabled: bool)` and source-specific period/stagger presets independent of blending.

- [x] Add optional demo control; change supported source presets together and reset unsupported sources visibly.
- [x] Document settings, approximate measured presets, phase assumptions, degeneration, triplanar limits, and reproduction commands.
- [x] Inspect test-agent evidence and validate demo parsing via its smoke check.
- [x] Refresh the code-only archive after coordinator approval and verify archive contents.
