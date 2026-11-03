# Later work and experiments

The tool's baseline is Morten Mikkelsen's [Practical Real-Time Hex-Tiling](https://jcgt.org/published/0011/03/05/) (2022). Its optional paper mode adapts luminance-weighted blending and normal-slope blending to this project's world-space triplanar material; it is not an exact reference implementation.

Relevant later work includes:

- Bartlomiej Wronski, [GPU-Friendly Laplacian Texture Blending](https://jcgt.org/published/0014/01/02/) (2025): uses mip-derived frequency bands and different blending radii to address ghosting and loss of detail. It introduces additional texture sampling and discusses haloing, overshoot, and animated aliasing. A small, incomplete two-band experiment is recorded in [two_band](two_band/); it did not establish an improvement in our test, so it is not shipped.
- Nicolas Lutz and Guillaume Gilet, [Real-time by-example texture synthesis and filtering using local statistics exchange](https://doi.org/10.1111/cgf.70355) (2026): changes the local appearance of regions within a periodic exemplar. It requires a region map and precomputed statistics, and its paper discusses additional PBR and filtering limitations. This is a promising distinct approach for structured materials, but is not implemented here.
- Pharr et al., [Filtering After Shading with Stochastic Texture Filtering](https://research.nvidia.com/labs/rtr/publication/pharr2024stochtex/) (2024): addresses filtering after shading, a different problem from suppressing visible texture repetition. It should not be presented as a drop-in detiling improvement.

None of these references imply that this project implements or reproduces their results. Improvements need matched visual comparisons, temporal checks, and target-device GPU profiling before being described as better.
