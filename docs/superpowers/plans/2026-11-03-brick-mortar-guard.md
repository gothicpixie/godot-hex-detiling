# Brick mortar guard implementation

- [x] Verify the clean baseline and establish failing guard-interface/GPU checks before production changes.
- [x] Generate a source-aligned conservative black-mortar/white-interior mask with provenance and repeat-safe preprocessing (mask agent).
- [x] Add guard uniforms, shared residual-anchor weighting, and coherent route precedence while preserving disabled paths (implementation agent).
- [x] Add the eligible Brick 4 demo control and clear stale guard bindings; document constraints and sampling cost.
- [x] Run synthetic GPU checks, UI regression checks, and matched brick captures; review mask and images before drawing quality conclusions (test agent and coordinator).
- [x] Inspect the final diff and evidence; do not commit or publish until coordinator review.

Completed after the expected RED failure, final passing GPU/UI evidence, matched capture review, independent evidence GO, and coordinator authorization for 0.6.0 integration/publication. Validation details are in `docs/brick_guard/VALIDATION.md`.
