"""Assemble matched GPU captures; native crops and no color adjustments."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/structure'
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',20)
small=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16)
modes=['periodic','offset','rotated','structured']
labels=['Periodic','Unconstrained offsets','Unrestricted rotation','Structure-aware']
for view in ['wall','oblique','elevated']:
    w,h=400,225
    sheet=Image.new('RGB',(w*4,44+3*(h+30)),'#182127')
    draw=ImageDraw.Draw(sheet)
    for c,label in enumerate(labels):draw.text((c*w+10,12),label,font=font,fill='white')
    for r,name in enumerate(['brick','wood','paving']):
        y=44+r*(h+30)
        draw.text((10,y+5),f'{name.title()} | {view} | matched scale 2.5 m, seed 0',font=small,fill='#c7d2cf')
        for c,mode in enumerate(modes):
            image=Image.open(OUT/f'{name}-{view}-{mode}.png').convert('RGB')
            image=image.resize((w,h),Image.Resampling.LANCZOS)
            sheet.paste(image,(c*w,y+30))
    sheet.save(OUT/f'{view}-comparison.jpg',quality=95)
# Native 1:1 center crops; same rectangle for all columns.
rect=(280,120,680,420)
sheet=Image.new('RGB',(1600,44+3*334),'#182127')
draw=ImageDraw.Draw(sheet)
for c,label in enumerate(labels):draw.text((c*400+10,12),label,font=font,fill='white')
for r,name in enumerate(['brick','wood','paving']):
    y=44+r*334
    draw.text((10,y+5),name.title()+' | wall, native 400 x 300 crop',font=small,fill='#c7d2cf')
    for c,mode in enumerate(modes):
        image=Image.open(OUT/f'{name}-wall-{mode}.png').convert('RGB')
        assert image.size==(960,540)
        sheet.paste(image.crop(rect),(c*400,y+30))
sheet.save(OUT/'native-detail-crops.png')
(OUT/'crop-settings.json').write_text(json.dumps({'source_size':[960,540],'rect_xyxy':rect,'pixel_scale':'1:1','color_adjustments':'none','resampling':'none'},indent=2)+'\n')
# Fixture metrics refer only to controlled shader probes, never source-photo quality.
import re
log=(OUT/'probe.log').read_text()
metrics={
    'fixture_only':True,
    'framebuffer':'8-bit clamped display channels',
    'structure_phase_max_error_threshold':0.008,
    'unconstrained_checker_clipped_mean_absolute_phase_error':float(re.search(r'offset-only phase damage; mean=([0-9.]+)',log)[1]),
    'structured_microappearance_mean_absolute_difference_shared':float(re.search(r'varies paper=false mean=([0-9.]+)',log)[1]),
    'structured_microappearance_mean_absolute_difference_paper':float(re.search(r'varies paper=true mean=([0-9.]+)',log)[1]),
    'structure_probe_passes':len(re.findall(r'^PASS:',log,re.M)),
    'structure_probe_failures':len(re.findall(r'^FAIL:',log,re.M)),
    'source_material_assessment':'Qualitative matched captures only; no source photograph quality score.'
}
(OUT/'fixture-results.json').write_text(json.dumps(metrics,indent=2)+'\n')
