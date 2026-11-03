"""Analyze matched frame sequences; keep only worst stills and actual-motion GIFs."""
from pathlib import Path
import json
import sys
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/guard_optimization'
RAW=Path('/tmp/guard-optimization-motion')
approach_only="--approach-only" in sys.argv
records=[]
if approach_only:
    records=[r for r in json.loads((OUT/"motion-summary.json").read_text())["sequences"] if not r["sequence"].startswith("approach-retreat")]
for directory in sorted(RAW.iterdir()):
    if approach_only and not directory.name.startswith("approach-retreat"): continue
    old=[]; new=[]; per=[]; inc=[]
    for i in range(48):
        a=np.asarray(Image.open(directory/f'old-{i:03}.png').convert('RGB'),dtype=np.float32)/255
        b=np.asarray(Image.open(directory/f'new-{i:03}.png').convert('RGB'),dtype=np.float32)/255
        e=b-a
        per.append({'frame':i,'max':float(abs(e).max()),'mean':float(abs(e).mean()),'rmse':float(np.sqrt(np.mean(e*e)))})
        if old:
            # Compare increments at matched camera positions, not raw camera motion.
            d=(b-new[-1])-(a-old[-1])
            inc.append({'frame':i,'max':float(abs(d).max()),'mean':float(abs(d).mean()),'rmse':float(np.sqrt(np.mean(d*d)))})
        old.append(a); new.append(b)
    worst=max(per,key=lambda r:(r['max'],r['rmse']))
    Image.open(directory/f"old-{worst['frame']:03}.png").save(OUT/f'{directory.name}-worst-old.png')
    Image.open(directory/f"new-{worst['frame']:03}.png").save(OUT/f'{directory.name}-worst-new.png')
    records.append({'sequence':directory.name,'frames':48,'worst_frame':worst,'per_frame':per,'increment_error':inc,'max_increment_error':max(x['max'] for x in inc),'max_increment_rmse':max(x['rmse'] for x in inc),'outlier_frames_over_2_bytes':[r['frame'] for r in per if r['max']>2/255+1e-7]})
    if directory.name.startswith(('approach-retreat','terrain')):
        frames=[]
        for i in range(48):
            canvas=Image.new('RGB',(768,242),(20,25,29))
            for j,prefix in enumerate(['old','new']):
                im=Image.open(directory/f'{prefix}-{i:03}.png').convert('RGB').resize((384,216))
                canvas.paste(im,(384*j,26))
            ImageDraw.Draw(canvas).text((8,7),f'v0.6.0 frozen       {directory.name} actual camera motion',fill='white')
            ImageDraw.Draw(canvas).text((392,7),f'optimized        frame {i+1}/48',fill='white')
            frames.append(canvas)
        frames[0].save(OUT/f'{directory.name}-motion.gif',save_all=True,append_images=frames[1:],duration=80,loop=0,optimize=True)
(OUT/'motion-summary.json').write_text(json.dumps({'frames_total':sum(r['frames'] for r in records),'quantization':'RGBA8','frame_tolerance':2/255,'increment_tolerance':4/255,'comparison':'(new[t]-new[t-1]) - (old[t]-old[t-1]), same camera each t','sequences':records},indent=2))
print(json.dumps([{k:v for k,v in r.items() if k not in ('per_frame','increment_error')} for r in records],indent=2))
