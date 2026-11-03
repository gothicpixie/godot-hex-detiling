# Coherent material blending

Goal: synthesize a useful extension to the current Godot shader, keeping existing modes and demonstrable improvements. This is a project-specific combination of known methods, not a claim of research novelty.

## Approaches

A full Laplacian blend adds samples and needs separate evaluation after the inconclusive two-band experiment. Structure-preserving tiling needs authoring/preprocessing information. The selected engineering proposal combines shared content guidance with footprint-dependent blend relaxation, using only samples already required for PBR. Selection is the implementer's judgment under the user's request to synthesize and keep improvements.

## Design

Add opt-in `coherent_blend` and `coherent_filter` (default true). Coherent mode takes precedence over `paper_blend`; existing modes and defaults retain their behavior. Per projection, sample three albedos, three normals, and optionally three roughnesses using existing transforms and explicit gradients. Combine bounded luminance and normal slope magnitude signals by a weighted geometric mean; normal_strength controls the normal cue's contribution. Roughness follows the same weights but does not vote: roughness is not a general measure of feature importance. Apply the same normalized weights to color, slopes, and roughness.

Use the maximum screen derivative length times the lattice scale to estimate footprint. Between 0.125 and 0.5 lattice units per pixel, smoothly reduce content guidance and blend contrast and relax the base exponent toward one. This is a heuristic attenuation, not analytic filtering of the procedural mask. Keep mip-aware texture sampling and optional detrending. No extra texture fetches relative to full PBR detiling with the same detrending setting.

## Evidence and limits

GPU tests must check normalized nonnegative weights, zero support on edges, permutation symmetry, constant inputs, far-footprint independence of guidance, disabled-normal independence, and PBR channel coherence using correlated synthetic maps. Preserve the existing GPU probe and smoke checks. Capture all nine materials, including structured failures, across terrain, wall, sphere and multiple views. Benchmark process-frame intervals honestly, with GPU samples only if available. Keep default mode unchanged. Do not assert improved perception or temporal stability from stills alone, histogram preservation, structural preservation, or world-first novelty.
