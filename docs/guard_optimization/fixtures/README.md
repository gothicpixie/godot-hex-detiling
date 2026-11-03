Immutable MIT-licensed production fixtures from commit `3b9216b` (v0.6.0): both shader and coherent helper come from that same commit. The test loader embeds the frozen helper, so no current include is used. Regenerate only by explicitly changing the reference version.

`pre-guard-6c9cabf.*` is the full matching MIT-licensed shader/helper pair from `6c9cabf`, used only by historical guard-disabled regression contracts. It is deliberately separate from the v0.6.0 performance/equivalence reference.

`pre-structure-5b86dca.*` is the matching shader/helper pair from `5b86dca` for the existing structure-disabled regression. Missing baseline fixtures fail the test rather than silently skipping it.
