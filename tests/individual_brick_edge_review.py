"""Keep adverse edge neighborhoods visible; never label proxy peaks physical joints."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/individual_brick';RAW=Path('/tmp/individual-brick-evaluation')
def luminance(a):
 a=np.asarray(a.convert('RGB'),dtype=float)/255;a=np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4);return a@np.array([.2126,.7152,.0722])
selected=[]
for seed in [0,7]:
 ai=Image.open(RAW/f'pbr-close-seed{seed}-baseline.png').convert('RGB');bi=Image.open(RAW/f'pbr-close-seed{seed}-individual.png').convert('RGB');a=luminance(ai);b=luminance(bi);mask=np.asarray(Image.open(RAW/f'channel-close-seed{seed}-mask-baseline.png'))[:,:,0]/255;profiles=[]
 for y in range(50,a.shape[0]-50,23):
  for x in np.where((mask[y,1:]>0.5)!=(mask[y,:-1]>0.5))[0]:
   if x<25 or x>a.shape[1]-25:continue
   aa=a[y,x-16:x+17];bb=b[y,x-16:x+17];ga=abs(np.diff(aa));gb=abs(np.diff(bb));ia=int(np.argmax(ga));ib=int(np.argmax(gb))
   if ga[ia]<.004:continue
   ca=(aa.max()-aa.min())/(aa.mean()+1e-9);cb=(bb.max()-bb.min())/(bb.mean()+1e-9)
   profiles.append({'seed':seed,'x_mask_crossing':int(x),'y':y,'baseline_peak_x':int(x-16+ia),'candidate_peak_x':int(x-16+ib),'peak_shift_px':abs(ib-ia),'contrast_ratio':float(cb/ca)})
 # One largest peak shift and one greatest contrast loss per seed, spatially distinct.
 worst_shift=max(profiles,key=lambda r:(r['peak_shift_px'],-r['contrast_ratio']))
 other=[r for r in profiles if abs(r['x_mask_crossing']-worst_shift['x_mask_crossing'])>80 or abs(r['y']-worst_shift['y'])>50]
 worst_contrast=min(other,key=lambda r:r['contrast_ratio'])
 for kind,r in [('peak-shift',worst_shift),('contrast-loss',worst_contrast)]:
  x=r['x_mask_crossing'];y=r['y'];left=max(0,min(x-200,ai.width-400));top=max(0,min(y-100,ai.height-200));crop=(left,top,left+400,top+200)
  canvas=Image.new('RGB',(800,240),(20,24,28));d=ImageDraw.Draw(canvas)
  for j,(im,label,peak) in enumerate([(ai,'Baseline',r['baseline_peak_x']),(bi,'Individual',r['candidate_peak_x'])]):
   canvas.paste(im.crop(crop),(400*j,40));d.text((400*j+6,5),f'{label} - native pixels - seed{seed}',fill='white');d.text((400*j+6,21),f"{kind}: shift{r['peak_shift_px']}px contrast{r['contrast_ratio']:.3f}",fill='white')
   yy=y-top+40;xx=x-left+400*j;pk=peak-left+400*j
   d.line((x-16-left+400*j,yy,x+16-left+400*j,yy),fill=(255,220,30),width=1)
   d.line((xx,yy-9,xx,yy+9),fill=(30,230,255),width=1)
   d.line((pk,yy-5,pk,yy+5),fill=(255,50,180),width=1)
  filename=f'edge-tail-{kind}-seed{seed}.png';canvas.save(OUT/filename);r.update(kind=kind,image=filename,crop=list(crop),annotation='yellow=33px profile; cyan=mask0.5 crossing; magenta=strongest luminance gradient (proxy, not physical joint)');selected.append(r)
(OUT/'edge-tail-review.json').write_text(json.dumps(selected,indent=2));print(json.dumps(selected,indent=2))
