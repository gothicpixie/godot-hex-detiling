from pathlib import Path
import json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/brick_atlas_release';RAW=Path('/tmp/brick-atlas-materials')
x=json.loads((OUT/'material-motion-settings.json').read_text());pairs={}
for r in x['records']:pairs.setdefault((r['material'],r['frame']),{})[r['arm']]=r
assert len(pairs)==24 and all(set(p)=={'baseline','candidate'} for p in pairs.values())
for p in pairs.values():assert p['baseline']['camera']==p['candidate']['camera']
for material in ['red_brick','large_red_bricks']:
 frames=[]
 for frame in range(12):
  im=Image.new('RGB',(1280,390),(20,24,28));d=ImageDraw.Draw(im)
  for j,arm in enumerate(['baseline','candidate']):
   image=Image.open(RAW/f'{material}-orbit-{arm}-{frame:02}.png').convert('RGB');im.paste(image,(j*640,30));d.text((j*640+8,8),f'{material} {arm} actual cylinder orbit {frame+1}/12',fill='white')
  frames.append(im)
 frames[0].save(OUT/f'{material}-orbit.gif',save_all=True,append_images=frames[1:],duration=160,loop=0,optimize=True)
(OUT/'material-motion-audit.json').write_text(json.dumps({'matched_poses':24,'camera_differences':0,'raw_moving_frame_difference_not_flicker_metric':True},indent=2))
