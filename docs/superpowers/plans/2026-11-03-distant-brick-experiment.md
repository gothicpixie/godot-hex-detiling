# Distant Brick Experiment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Test reduced distant tonal repetition while preserving mortar structure.
**Architecture:** Offline luminance normalization plus a bounded filtered world-space scalar color field after material sampling; default-off Brick 4 demo opt-in.
**Tech Stack:** Godot shader/GDScript, Python image analysis.
**Spec:** `docs/superpowers/specs/2026-11-03-distant-brick-experiment.md`

## Global Constraints

- Local branch `codex/distant-brick-variation`; no publication or commit before root review.
- Keep original assets, normal/roughness, guard alpha/cutoff, donor mixture and source-only returns unchanged.
- `brick_macro_enabled=false`; `brick_macro_strength=0.18`; strength zero bypasses modulation.
- GPU evaluation belongs exclusively to the test worker.

## Review Focus

- Macro gain changes color only; normalization may change interior PBR mixture weights, but protected normal/roughness and geometry stay unchanged.
- Normalization preserves guard alpha and source alignment.
- Off-mode output and demo restoration match v0.7.0.
- World anchoring and pixel-footprint filtering prevent camera-phase changes.
- Repetition metrics distinguish expected brick spacing from repeated source patches.

### Task 1: Asset and implementation

- [x] Test worker records RED for missing default-off macro interface in `tests/distant_brick_smoke.gd`.
- [x] Asset worker produces `assets/gallery/brick_4_albedo_guard_normalized.png`, import settings and provenance; originals unchanged.
- [x] Add filtered scalar macro helper and uniforms to `addons/hex_detile/hex_detile.gdshader`; retain coherent helper unchanged.
- [x] Add `brick_macro_toggle` and preference to `demo.gd`, selecting the normalized asset only for the active experiment.
- [x] Freeze source and hand GPU to tester; verify UI/default-off controls and all four ablations.

### Task 2: Evaluate and report

- [x] Test worker captures matched distance/grazing/motion, tonal repetition and mortar-edge metrics, protected normal/roughness and off-mode invariants; report interior PBR mixture changes separately.
- [x] Write bounded results and native before/after evidence in `docs/distant_brick/README.md`; do not claim success before inspection.
- [x] Root reviews evidence and decides whether to retain, revise or reject; no automatic publication.


Execution result: four-arm metrics and native images show partial tonal improvement but overall repetition target FAIL: combined distant periodic energy is about 51% lower, full-source correlation falls only 12.3% / 11.4%, and repeated patches remain visible. Intermediate seed 7 narrowly exceeds the 10% mean-brightness tolerance. Sampled mortar proxies retain alignment/sharpness; protected PBR differences stay within one byte and distant source-only PBR matches. Off/strength-zero controls show zero observed byte difference; nine regressions pass. Actual camera motions and a fixed-world macro probe support bounded stability, not universal alias freedom. Root approved preserving this honest result as a local experimental commit, default off; no merge, version/archive update or publication is authorized.
