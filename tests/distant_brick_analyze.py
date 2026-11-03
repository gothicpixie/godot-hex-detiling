"""Independent finite four-arm repetition, channel and mortar evaluation."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
from scipy.ndimage import gaussian_filter,shift
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'docs/distant_brick'; RAW=Path('/tmp/distant-brick-evaluation')
ARMS=['baseline','normalization','macro','both']
def rgb(path): return np.asarray(Image.open(path).convert('RGB'),dtype=np.float64)/255
def linear(a): return np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4)
def lum(a): return linear(a)@np.array([.2126,.7152,.0722])
def metrics(path,period):
    a=rgb(path);y=lum(a);p=int(round(period));b=gaussian_filter(y,period/32,mode='nearest');h=(b.shape[0]//p)*p;w=(b.shape[1]//p)*p;b=b[:h,:w];mean=float(b.mean())
    ac=[]
    for axis in [0,1]:
        x=b[:-p,:] if axis==0 else b[:,:-p];z=b[p:,:] if axis==0 else b[:,p:]
        ac.append(float(np.corrcoef(x.ravel(),z.ravel())[0,1]))
    spectrum=np.fft.fft2(b-b.mean(),norm='forward');energy=0.
    for ky in range(-6,7):
        for kx in range(-6,7):
            if not(kx or ky):continue
            energy+=abs(spectrum[(ky*(h//p))%h,(kx*(w//p))%w])**2
    return {'period_px':period,'crop':[w,h],'mean_linear_luminance':mean,'linear_luminance_std':float(y.std()),'blurred_std':float(b.std()),'normalized_full_source_autocorrelation_xy':[ac[1],ac[0]],'autocorrelation_mean':float(np.mean(ac)),'absolute_periodic_energy':float(energy),'mean_normalized_periodic_energy':float(energy/mean**2),'periodic_energy_over_total_variance':float(energy/b.var()),'fraction_any_channel_255':float(np.mean(np.max(a,axis=2)>=1))}
def labeled_pair(a,b,path,labela,labelb,crop=None):
    a=Image.open(a).convert('RGB');b=Image.open(b).convert('RGB')
    if crop: a=a.crop(crop);b=b.crop(crop)
    else:a=a.resize((640,360));b=b.resize((640,360))
    canvas=Image.new('RGB',(a.width+b.width,a.height+30),(20,24,28));canvas.paste(a,(0,30));canvas.paste(b,(a.width,30));d=ImageDraw.Draw(canvas);d.text((8,8),labela,fill='white');d.text((a.width+8,8),labelb,fill='white');canvas.save(path)
settings=json.loads((OUT/'capture-settings.json').read_text());rows=[]
for r in settings['records']:
    if r['kind']!='ortho':continue
    m=metrics(RAW/(r['id']+'.png'),r['repeat_px'][0]);rows.append({**r,**m})
comparisons=[]
for size in [7.5,30.]:
    for seed in [0,7]:
        values={r['arm']:r for r in rows if r['size']==size and r['seed']==seed};base=values['baseline']
        for arm in ARMS[1:]:
            r=values[arm];comparisons.append({'size':size,'seed':seed,'arm':arm,'periodic_energy_ratio':r['mean_normalized_periodic_energy']/base['mean_normalized_periodic_energy'],'absolute_energy_ratio':r['absolute_periodic_energy']/base['absolute_periodic_energy'],'autocorrelation_ratio':r['autocorrelation_mean']/base['autocorrelation_mean'],'mean_luminance_ratio':r['mean_linear_luminance']/base['mean_linear_luminance'],'variance_ratio':r['linear_luminance_std']**2/base['linear_luminance_std']**2})
channels=[]
for view in ['close','grazing','distant']:
    for seed in [0,7]:
        mask=rgb(RAW/f'channel-{view}-seed{seed}-mask-baseline.png')[:,:,0]<1/255
        for channel in ['normal','roughness']:
            a=rgb(RAW/f'channel-{view}-seed{seed}-{channel}-baseline.png');b=rgb(RAW/f'channel-{view}-seed{seed}-{channel}-both.png');d=np.abs(a-b)
            channels.append({'view':view,'seed':seed,'channel':channel,'protected_pixels':int(mask.sum()),'protected_max':float(d[mask].max()) if mask.any() else None,'all_pixel_max':float(d.max()),'all_pixel_mean':float(d.mean())})
# Native mortar edge neighborhoods: use actual captured mask boundaries, compare luminance gradients.
edges=[]
for seed in [0,7]:
    a=lum(rgb(RAW/f'pbr-close-seed{seed}-baseline.png'));b=lum(rgb(RAW/f'pbr-close-seed{seed}-both.png'));mask=rgb(RAW/f'channel-close-seed{seed}-mask-baseline.png')[:,:,0]
    shifts=[];widths=[];contrast=[]
    for y in range(50,a.shape[0]-50,23):
        boundaries=np.where((mask[y,1:]>0.5)!=(mask[y,:-1]>0.5))[0]
        for x in boundaries:
            if x<25 or x>a.shape[1]-25:continue
            aa=a[y,x-16:x+17];bb=b[y,x-16:x+17];ga=np.abs(np.diff(aa));gb=np.abs(np.diff(bb));ia=int(np.argmax(ga));ib=int(np.argmax(gb))
            if ga[ia]<0.004:continue
            shifts.append(abs(ib-ia));indices=np.arange(32)
            wa=np.sqrt(np.sum(ga*(indices-ia)**2)/ga.sum());wb=np.sqrt(np.sum(gb*(indices-ib)**2)/gb.sum());widths.append(wb/wa if wa else 1)
            ca=(aa.max()-aa.min())/(aa.mean()+1e-9);cb=(bb.max()-bb.min())/(bb.mean()+1e-9);contrast.append(cb/ca)
    edges.append({'seed':seed,'edge_neighborhood_count':len(shifts),'median_peak_shift_px':float(np.median(shifts)),'p95_peak_shift_px':float(np.percentile(shifts,95)),'median_gradient_width_ratio':float(np.median(widths)),'median_local_contrast_ratio':float(np.median(contrast)),'p05_local_contrast_ratio':float(np.percentile(contrast,5))})
result={'method':'linear luminance Gaussian sigma=sourceperiod/32; exact known full-source autocorr lags; raw Fourier phase-locked source harmonics1..6; no dropped cases','records':rows,'comparisons':comparisons,'channels':channels,'edge_neighborhoods':edges}
(OUT/'metrics.json').write_text(json.dumps(result,indent=2))
for seed in [0,7]:
    labeled_pair(RAW/f'ortho-30.0-seed{seed}-baseline.png',RAW/f'ortho-30.0-seed{seed}-both.png',OUT/f'distant-wall-seed{seed}.png','Baseline v0.7.0','Normalization + stable macro')
    labeled_pair(RAW/f'pbr-close-seed{seed}-baseline.png',RAW/f'pbr-close-seed{seed}-both.png',OUT/f'close-mortar-native-seed{seed}.png','Baseline mortar - native pixels','Candidate mortar - native pixels',(320,160,960,560))
    labeled_pair(RAW/f'ortho-30.0-seed{seed}-baseline.png',RAW/f'ortho-30.0-seed{seed}-both.png',OUT/f'distant-native-seed{seed}.png','Baseline distant - native pixels','Candidate distant - native pixels',(320,160,960,560))
    for kind in ['close','grazing','distant']:
        labeled_pair(RAW/f'pbr-{kind}-seed{seed}-baseline.png',RAW/f'pbr-{kind}-seed{seed}-both.png',OUT/f'pbr-{kind}-seed{seed}.png','Baseline v0.7.0',f'Candidate - {kind}')
for size in [7.5,30.]:
    for seed in [0,7]:
        canvas=Image.new('RGB',(1280,780),(20,24,28));d=ImageDraw.Draw(canvas)
        for i,arm in enumerate(ARMS):
            a=Image.open(RAW/f'ortho-{size}-seed{seed}-{arm}.png').convert('RGB').resize((640,360));x=(i%2)*640;y=(i//2)*390;canvas.paste(a,(x,y+30));d.text((x+8,y+8),arm,fill='white')
        canvas.save(OUT/f'four-arms-{size}-seed{seed}.png')
print(json.dumps({'comparisons':comparisons,'channels':channels,'edges':edges},indent=2))
