# Individual Brick Experiment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Evaluate independently recolored actual bricks while preserving mortar.
**Architecture:** Offline segmented 4×4 full-resolution palette atlas plus aligned stochastic integer-tile palette blending and periodic source PBR in a default-off material route.
**Tech Stack:** Godot shader/GDScript; Python image preprocessing and evaluation.
**Spec:** `docs/superpowers/specs/2026-11-03-individual-brick-experiment.md`

## Global Constraints

- Branch `codex/individual-brick-variation`, based on prior experimentd0fcb5e.
- No merge/push/release or version/archive change without separate root authorization.
- Atlas4096², four source spans, protected native RGB exact, original assets unchanged.
- `brick_individual_enabled=false`, sampler `brick_individual_map`; demo primary palette0, test palette7 separately; variation seed controls stochastic world layout.
- Explicit gradient scaling and mipmapped color; never filtered IDs.
- Tester exclusively owns GPU execution after source handoff.

## Review Focus

- Cross-source and atlas-seam bricks receive consistent palette entries.
- New color fine detail aligns with original normal/roughness; near donor mixtures intentionally bypassed.
- Protected RGB/PBR and mortar-edge profiles remain preserved at resolved scales.
- Original-source and new full-atlas repetition are both measured.
- Off mode, UI restoration, filtering and actual motion remain stable within tested scope.

### Task 1: Asset and material route

- [x] Tester records RED for missing default-off interface in `tests/individual_brick_smoke.gd`.
- [x] Asset worker produces palette0/7 atlases, linear-data-safe imports, region audit and provenance in `docs/individual_brick/`.
- [x] Implement independent source-PBR triplanar route in `addons/hex_detile/hex_detile.gdshader` with all gradients before calls; keep coherent helper unchanged.
- [x] Add `brick_individual_toggle`, stored preference, eligibility/precedence and sampler binding to `demo.gd`.
- [x] Freeze source and hand GPU to tester; no concurrent GPU work.

### Task 2: Evidence and decision

- [x] Tester evaluates all four arms, two palette seeds, source/atlas repeat metrics, native mortar/PBR and motion, plus fresh off-mode regressions.
- [x] Write concise inspectable results in `docs/individual_brick/README.md`, including finite period, memory/cost and any failure.
- [x] Root reviews native comparisons/evidence before deciding whether to preserve the experiment locally; no automatic publication.

Ruling: root requested a fourth aligned-stochastic atlas arm before evaluation. Integer original-source offsets preserve geometry phase; direct-atlas remains an ablation. Fixed lattice input `uv/2`, smooth shared barycentrics, global-mean coarse fallback, and max sixteen full-PBR reads are explicit experiment decisions. No GPU measurements support a timing claim.

Ruling: the first linear-weight primary passed repetition targets but retained only47.1% /48.2% of original GPU between-brick variance, below the predeclared50% guard. Root authorized one bounded adjustment: square the shared barycentric weights before normalization. Tester froze linear source/evidence before this one-line change. No asset, grid, mask or criterion threshold changes are permitted; final primary must be recaptured and judged against the original criteria.

Final result: the squared-weight primary meets the declared repetition and palette-variance targets for both distant seeds, with materially lower color correlation at original-source and four-source lags. Ten regressions and off-mode controls pass; continuity probes and 64 matched camera poses are retained. CPU protected RGB/alpha remain exact; rendered protected RGB is within one byte and protected PBR matches. Native tail review distinguishes strongest-feature switching from joint movement while disclosing substantial local contrast changes and retained dark rims. Root approved a local experimental commit only. No merge, push, release or version/archive update is authorized.
