"""Assemble real captures and quantify the isolated mask-filter experiment."""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs' / 'coherent'
try:
    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 20)
    small = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 16)
except OSError:
    font = small = ImageFont.load_default()


def sheet(names, filename, width=420):
    modes = ['shared', 'paper', 'coherent']
    height = round(width * 540 / 960)
    canvas = Image.new('RGB', (3 * width, len(names) * (height + 34) + 42), '#182127')
    draw = ImageDraw.Draw(canvas)
    for col, title in enumerate(['Shared weights', 'Paper-inspired', 'Coherent material']):
        draw.text((col * width + 12, 10), title, font=font, fill='#f1eee6')
    for row, name in enumerate(names):
        y = 42 + row * (height + 34)
        for col, mode in enumerate(modes):
            source = Image.open(OUT / f'{name}-{mode}.jpg').convert('RGB')
            source.thumbnail((width, height), Image.Resampling.LANCZOS)
            canvas.paste(source, (col * width, y + 28))
        label = name.replace('-', ' ').title()
        manifest = OUT / 'capture-settings.json'
        if manifest.exists():
            metadata = json.loads(manifest.read_text())
            entry = next((item for item in metadata['captures'] if item['id'] == name), None)
            if entry:
                label += ' | ' + entry['mesh'] + ' | scale ' + str(entry['texture_scale_m']) + ' m'
        draw.text((12, y + 3), label, font=small, fill='#c7d2cf')
    canvas.save(OUT / filename, quality=94)



def source_palette():
    # Read the actual demo constants, preserving material order and source paths.
    import re
    import hashlib
    demo = (ROOT / 'demo.gd').read_text()
    name_block = demo.split('const TEXTURE_NAMES := [', 1)[1].split(']\n', 1)[0]
    map_block = demo.split('const TEXTURE_SETS := [', 1)[1].split(']\n', 1)[0]
    names = re.findall(r'"([^"\n]+)"', name_block)
    sources = re.findall(r'\["(res://[^"\n]+)"', map_block)
    assert len(names) == len(sources) >= 17
    # This historical comparison covers its original seventeen capture sources.
    names, sources = names[:17], sources[:17]
    cell, patch, columns, row_height = 232, 208, 5, 262
    canvas = Image.new('RGB', (columns * cell, 74 + 4 * row_height), '#182127')
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 12), 'Source albedo textures — not shader renders', font=font, fill='#f1eee6')
    draw.text((12, 42), '17 demo materials | full source images reduced to 208 px | no color adjustment', font=small, fill='#c7d2cf')
    records = []
    for index, (name, source) in enumerate(zip(names, sources)):
        path = ROOT / source.removeprefix('res://')
        original = Image.open(path).convert('RGB')
        image = original.resize((patch, patch), Image.Resampling.LANCZOS)
        x, y = index % columns * cell + 12, 74 + index // columns * row_height
        canvas.paste(image, (x, y))
        words, lines, line = name.split(), [], ''
        for word in words:
            trial = (line + ' ' + word).strip()
            if draw.textlength(trial, font=small) > patch and line:
                lines.append(line)
                line = word
            else:
                line = trial
        lines.append(line)
        draw.multiline_text((x, y + patch + 6), '\n'.join(lines), font=small, fill='#f1eee6', spacing=2)
        records.append({'texture_index': index, 'name': name, 'source': source, 'source_size': list(original.size), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    canvas.save(OUT / 'source-albedo-palette.png')
    (OUT / 'source-albedo-palette.json').write_text(json.dumps({'caption': 'Source albedo textures — not shader renders', 'patch_size': [patch, patch], 'resampling': 'Lanczos', 'color_adjustment': 'none', 'materials': records}, indent=2) + '\n')


def detail_crops():
    # Crop rectangles are x,y,width,height in the existing 960x540 captures.
    # Paste native pixels without resampling; columns always use the same rect.
    crops = [('plaster', [280, 120, 400, 300]), ('leather', [368, 130, 224, 300]),
             ('terrazzo', [280, 120, 400, 300]), ('rubber', [368, 130, 224, 300])]
    width, row_height = 400, 338
    canvas = Image.new('RGB', (3 * width, 76 + len(crops) * row_height), '#182127')
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 8), 'Shader-render detail crops | 1 source pixel = 1 sheet pixel | no color adjustment', font=font, fill='#f1eee6')
    for col, label in enumerate(['Shared weights', 'Paper-inspired', 'Coherent material']):
        draw.text((col * width + 12, 42), label, font=font, fill='#f1eee6')
    for row, (name, rect) in enumerate(crops):
        x, y, w, h = rect
        top = 76 + row * row_height
        draw.text((12, top + 4), name.title() + ' | crop x,y,w,h = ' + ','.join(map(str, rect)), font=small, fill='#c7d2cf')
        for col, mode in enumerate(['shared', 'paper', 'coherent']):
            original = Image.open(OUT / f'{name}-{mode}.jpg').convert('RGB')
            assert original.size == (960, 540)
            canvas.paste(original.crop((x, y, x + w, y + h)), (col * width + (width - w) // 2, top + 30))
    canvas.save(OUT / 'finish-detail-crops.png')
    (OUT / 'finish-detail-crops.json').write_text(json.dumps({'source_size': [960, 540], 'pixel_scale': '1:1', 'resampling': 'none', 'color_adjustment': 'none', 'rect_format': ['x', 'y', 'width', 'height'], 'modes': ['shared', 'paper', 'coherent'], 'crops': [{'id': name, 'rect': rect} for name, rect in crops]}, indent=2) + '\n')


source_palette()
detail_crops()

sheet(['boulder', 'sandstone', 'cobble'], 'organic-comparison.jpg')
sheet(['rocks', 'grass', 'denim'], 'surface-comparison.jpg')
sheet(['brick', 'wood', 'paving'], 'structured-comparison.jpg')
sheet(['snow', 'mud', 'sand'], 'terrain-comparison.jpg')
sheet(['plaster', 'terrazzo', 'rubber'], 'finish-comparison.jpg')
sheet(['leather', 'mossy-rock'], 'relief-comparison.jpg')
sheet(['cobble-grazing', 'cobble-elevated', 'boulder-oblique'], 'angle-comparison.jpg')

records = []
for scale in [2, 8, 20]:
    reference = Image.open(OUT / f'footprint-{scale}-reference.png').convert('RGB').resize((128, 128), Image.Resampling.BOX)
    reference.save(OUT / f'footprint-{scale}-reference-small.png')
    ref = list(reference.tobytes()[::3])
    record = {'scale': scale, 'lattice_units_per_pixel': scale / 128 * 2 * math.sqrt(3)}
    for mode in ['point', 'relaxed']:
        data = list(Image.open(OUT / f'footprint-{scale}-{mode}.png').convert('RGB').tobytes()[::3])
        mse = sum((p / 255 - q / 255) ** 2 for p, q in zip(data, ref)) / len(ref)
        record[mode + '_rmse'] = math.sqrt(mse)
    records.append(record)
(OUT / 'footprint-results.json').write_text(json.dumps(records, indent=2) + '\n')
canvas = Image.new('RGB', (3 * 384, 432), '#182127')
draw = ImageDraw.Draw(canvas)
for col, (mode, label) in enumerate([('point', 'Sharp point sample'), ('relaxed', 'Footprint relaxation'), ('reference-small', '8 x 8 reference average')]):
    frame = Image.open(OUT / f'footprint-20-{mode}.png').convert('RGB').resize((384, 384), Image.Resampling.NEAREST)
    canvas.paste(frame, (384 * col, 48))
    draw.text((384 * col + 12, 14), label, font=font, fill='#f1eee6')
canvas.save(OUT / 'footprint-comparison.png')
print(json.dumps(records, indent=2))

# Optional camera loop, using only the matched real captures above.
import os
if os.environ.get('HEX_CAPTURE_DIR'):
    frames = []
    source_dir = Path(os.environ['HEX_CAPTURE_DIR'])
    for index in range(24):
        frame = Image.new('RGB', (840, 186), '#182127')
        draw = ImageDraw.Draw(frame)
        for col, (mode, label) in enumerate([('shared', 'Shared weights'), ('paper', 'Paper-inspired'), ('coherent', 'Coherent material')]):
            source = Image.open(source_dir / f'{mode}-{index:02d}.png').convert('RGB').resize((280, 158), Image.Resampling.LANCZOS)
            frame.paste(source, (col * 280, 28))
            draw.text((col * 280 + 10, 4), label, font=small, fill='#f1eee6')
        frames.append(frame)
    # A shared palette avoids palette pumping between frames. GIF is a viewing
    # aid; lossy 256-color output cannot prove absence of temporal artifacts.
    palette = frames[12].quantize(colors=256)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    loop = indexed + indexed[-2:0:-1]
    loop[0].save(OUT / 'camera-loop.gif', save_all=True, append_images=loop[1:], duration=85, loop=0, optimize=False)
