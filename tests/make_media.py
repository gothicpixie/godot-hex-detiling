"""Build a compact two-frame comparison loop from the demo's captured images.

Requires Pillow. First run the Godot capture script described in the README.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1] / "docs"
frames = [
    Image.open(root / name).convert("RGB").resize((960, 540))
    for name in ("periodic.png", "detiled.png")
]
frames[0].save(root / "comparison.gif", save_all=True, append_images=frames[1:],
               duration=[1800, 1800], loop=0, optimize=True)
