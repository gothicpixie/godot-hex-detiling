"""Matched native crops; never change image colors or sharpen captures."""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'docs/brick_guard'
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',18)
for seed in (0,7):
 out=Image.new('RGB',(1200,1008),'#141414');d=ImageDraw.Draw(out)
 for row,view in enumerate(('wall','oblique','elevated')):
  for col,mode in enumerate(('periodic','structured','guarded')):
   im=Image.open(p/f'brick-{view}-seed{seed}-{mode}.png')
   crop=im.crop((440,210,840,510))
   yy=row*336
   out.paste(crop,(col*400,yy+36));d.text((col*400+10,yy+9),f'{view} / {mode} / seed {seed}',font=font,fill='white')
 out.save(p/f'native-comparison-seed{seed}.jpg',quality=95)
 # A/B uses original captured frames at native resolution.
 frames=[Image.open(p/f'brick-wall-seed{seed}-{m}.png').convert('RGB') for m in ('periodic','structured','guarded')]
 frames[0].save(p/f'wall-loop-seed{seed}.gif',save_all=True,append_images=frames[1:],duration=1400,loop=0)
