"""Independent finite four-arm repetition, channel and mortar evaluation."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
from scipy.ndimage import gaussian_filter,shift
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'docs/brick_atlas_release'; RAW=Path('/tmp/brick-atlas-release')
ARMS=['baseline','four','two','balanced','three']
def rgb(path): return np.asarray(Image.open(path).convert('RGB'),dtype=np.float64)/255
def linear(a): return np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4)
def lum(a): return linear(a)@np.array([.2126,.7152,.0722])
def correlation(a,lag):
    out=[]
    for axis in [0,1]:
        if a.shape[axis]<=lag:out.append(None);continue
        x=a[:-lag,:] if axis==0 else a[:,:-lag];z=a[lag:,:] if axis==0 else a[:,lag:]
        out.append(float(np.corrcoef(x.ravel(),z.ravel())[0,1]) if x.std()>1e-10 and z.std()>1e-10 else 0.)
    return [out[1],out[0]]
def periodic_energy(a,p,harmonics=6):
    h=(a.shape[0]//p)*p;w=(a.shape[1]//p)*p
    if h<2*p or w<2*p:return None
    a=a[:h,:w];spectrum=np.fft.fft2(a-a.mean(),norm='forward');energy=0.
    for ky in range(-harmonics,harmonics+1):
        for kx in range(-harmonics,harmonics+1):
            if not(kx or ky):continue
            energy+=abs(spectrum[(ky*(h//p))%h,(kx*(w//p))%w])**2
    return float(energy)
def metrics(path,period):
    a=rgb(path);l=linear(a);y=l@np.array([.2126,.7152,.0722]);p=int(round(period));sigma=period/16
    channels={'luminance':y,'R-G':l[:,:,0]-l[:,:,1],'B-G':l[:,:,2]-l[:,:,1]};values={}
    for name,channel in channels.items():
        blurred=gaussian_filter(channel,sigma,mode='nearest');ac=correlation(blurred,p);atlas_ac=correlation(blurred,p*4)
        values[name]={'source_repeat_correlation_xy':ac,'source_repeat_correlation_mean':float(np.mean([v for v in ac if v is not None])),'atlas_repeat_correlation_xy':atlas_ac,'source_periodic_energy':periodic_energy(blurred,p),'atlas_periodic_energy_same_frequency_band':periodic_energy(blurred,p*4,24),'variance':float(channel.var())}
    mean=float(y.mean());chroma_energy=values['R-G']['source_periodic_energy']+values['B-G']['source_periodic_energy']
    return {'period_px':period,'atlas_period_px':period*4,'blur_sigma_px':sigma,'mean_linear_luminance':mean,'linear_luminance_std':float(y.std()),'channels':values,'chroma_correlation_mean':float(np.mean([values[k]['source_repeat_correlation_mean'] for k in ['R-G','B-G']])),'chroma_periodic_energy':chroma_energy,'mean_normalized_chroma_periodic_energy':chroma_energy/mean**2,'mean_normalized_luma_periodic_energy':values['luminance']['source_periodic_energy']/mean**2,'fraction_any_channel_255':float(np.mean(np.max(a,axis=2)>=1))}

def brick_palette_metrics(path,period):
    a=linear(rgb(path));h,w=a.shape[:2];xs=(np.arange(w)+.5-w/2)/period;ys=(h/2-np.arange(h)-.5)/period
    ix=np.floor(np.mod(xs,4)*1024).astype(int);iy=np.floor(np.mod(ys,4)*1024).astype(int)
    regions=np.asarray(Image.open(ROOT/'docs/individual_brick/atlas-region-ids.png'),dtype=np.int32)
    alpha=np.asarray(Image.open(ROOT/'assets/gallery/brick_4_albedo_guard.png').convert('RGBA'))[:,:,3]
    ids=regions[iy[:,None],ix[None,:]];core=(alpha[iy[:,None]%1024,ix[None,:]%1024]==255)&(ids>0)
    n=int(regions.max())+1;keys=ids+n*(np.floor(xs/4).astype(int)[None,:]+100)+n*200*(np.floor(ys/4).astype(int)[:,None]+100)
    unique,inverse=np.unique(keys[core],return_inverse=True);count=np.bincount(inverse);valid=count>=4
    means=np.stack([np.bincount(inverse,weights=a[:,:,c][core])/count for c in range(3)],axis=1)[valid]
    return {'regions_with_4_core_pixels':int(valid.sum()),'between_brick_linear_rgb_variance':float(np.var(means,axis=0).sum()),'between_brick_opponent_chroma_variance':float(np.var(means[:,0]-means[:,1])+np.var(means[:,2]-means[:,1])),'method':'known orthographic projection and native toroidal atlas region labels; exact alpha255 interior core; matched spatial regions, >=4 captured core pixels; mean linear RGB per region'}

def labeled_pair(a,b,path,labela,labelb,crop=None):
    a=Image.open(a).convert('RGB');b=Image.open(b).convert('RGB')
    if crop: a=a.crop(crop);b=b.crop(crop)
    else:a=a.resize((640,360));b=b.resize((640,360))
    canvas=Image.new('RGB',(a.width+b.width,a.height+30),(20,24,28));canvas.paste(a,(0,30));canvas.paste(b,(a.width,30));d=ImageDraw.Draw(canvas);d.text((8,8),labela,fill='white');d.text((a.width+8,8),labelb,fill='white');canvas.save(path)
settings=json.loads((OUT/'capture-settings.json').read_text());rows=[]
for r in settings['records']:
    if r['kind']!='ortho':continue
    m=metrics(RAW/(r['id']+'.png'),r['repeat_px'][0]);m['brick_palette']=brick_palette_metrics(RAW/(r['id']+'.png'),r['repeat_px'][0]);rows.append({**r,**m})
comparisons=[]
for size in [7.5,30.]:
    for seed in [0,7]:
        values={r['arm']:r for r in rows if r['size']==size and r['seed']==seed};base=values['baseline']
        for arm in ARMS[1:]:
            r=values[arm];comparisons.append({'size':size,'seed':seed,'arm':arm,'chroma_periodic_energy_ratio':r['mean_normalized_chroma_periodic_energy']/base['mean_normalized_chroma_periodic_energy'],'luma_periodic_energy_ratio':r['mean_normalized_luma_periodic_energy']/base['mean_normalized_luma_periodic_energy'],'chroma_correlation_ratio':r['chroma_correlation_mean']/base['chroma_correlation_mean'],'luma_correlation_ratio':r['channels']['luminance']['source_repeat_correlation_mean']/base['channels']['luminance']['source_repeat_correlation_mean'],'mean_luminance_ratio':r['mean_linear_luminance']/base['mean_linear_luminance'],'variance_ratio':r['linear_luminance_std']**2/base['linear_luminance_std']**2,'between_brick_rgb_palette_variance_ratio':r['brick_palette']['between_brick_linear_rgb_variance']/base['brick_palette']['between_brick_linear_rgb_variance'],'between_brick_chromatic_palette_variance_ratio':r['brick_palette']['between_brick_opponent_chroma_variance']/base['brick_palette']['between_brick_opponent_chroma_variance']})
channels=[]
for view in ['close','grazing','distant']:
    for seed in [0,7]:
        mask=rgb(RAW/f'channel-{view}-seed{seed}-protected-baseline.png')[:,:,0]==0
        for channel in ['normal','roughness']:
            a=rgb(RAW/f'channel-{view}-seed{seed}-{channel}-baseline.png');b=rgb(RAW/f'channel-{view}-seed{seed}-{channel}-three.png');d=np.abs(a-b)
            channels.append({'view':view,'seed':seed,'channel':channel,'protected_pixels':int(mask.sum()),'protected_max':float(d[mask].max()) if mask.any() else None,'all_pixel_max':float(d.max()),'all_pixel_mean':float(d.mean())})
# Compare actual shaded RGB only where the production reference alpha is exactly zero.
protected_rgb=[]
for view in ['close','grazing','distant']:
    for seed in [0,7]:
        m=rgb(RAW/f'channel-{view}-seed{seed}-protected-baseline.png')[:,:,0]==0
        a=np.asarray(Image.open(RAW/f'pbr-{view}-seed{seed}-baseline.png').convert('RGB'),dtype=int)
        b=np.asarray(Image.open(RAW/f'pbr-{view}-seed{seed}-three.png').convert('RGB'),dtype=int);d=np.abs(a-b)
        protected_rgb.append({'view':view,'seed':seed,'canonical_exact_alpha0_pixels':int(m.sum()),'protected_max_byte_rgb_delta':int(d[m].max()) if m.any() else None,'protected_mean_byte_rgb_delta':float(d[m].mean()) if m.any() else None,'protected_changed_pixels':int(np.any(d[m]>0,axis=1).sum()) if m.any() else 0})
(OUT/'protected-rendered-rgb.json').write_text(json.dumps(protected_rgb,indent=2))

# Native mortar edge neighborhoods: use actual captured mask boundaries, compare luminance gradients.
edges=[]
for seed in [0,7]:
    a=lum(rgb(RAW/f'pbr-close-seed{seed}-baseline.png'));b=lum(rgb(RAW/f'pbr-close-seed{seed}-three.png'));mask=rgb(RAW/f'channel-close-seed{seed}-mask-baseline.png')[:,:,0]
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
    edges.append({'seed':seed,'edge_neighborhood_count':len(shifts),'median_peak_shift_px':float(np.median(shifts)),'p95_peak_shift_px':float(np.percentile(shifts,95)),'median_edge_profile_width_proxy_ratio':float(np.median(widths)),'median_local_contrast_ratio':float(np.median(contrast)),'p05_local_contrast_ratio':float(np.percentile(contrast,5))})
result={'method':'linear luminance and R-G/B-G; Gaussian sigma=sourceperiod/16 suppresses brick pitch; exact known source and4xatlas lags; raw Fourier source harmonics1..6; no dropped cases','records':rows,'comparisons':comparisons,'channels':channels,'edge_neighborhoods':edges}
(OUT/'metrics.json').write_text(json.dumps(result,indent=2))
for seed in [0,7]:
    labeled_pair(RAW/f'ortho-30.0-seed{seed}-baseline.png',RAW/f'ortho-30.0-seed{seed}-three.png',OUT/f'distant-wall-seed{seed}.png','Baseline v0.7.0','Individual bricks - macro OFF')
    labeled_pair(RAW/f'pbr-close-seed{seed}-baseline.png',RAW/f'pbr-close-seed{seed}-three.png',OUT/f'close-mortar-native-seed{seed}.png','Baseline mortar - native pixels','Individual bricks - native pixels',(320,160,960,560))
    labeled_pair(RAW/f'ortho-30.0-seed{seed}-baseline.png',RAW/f'ortho-30.0-seed{seed}-three.png',OUT/f'distant-native-seed{seed}.png','Baseline distant - native pixels','Candidate distant - native pixels',(320,160,960,560))
    for kind in ['close','grazing','distant']:
        labeled_pair(RAW/f'pbr-{kind}-seed{seed}-baseline.png',RAW/f'pbr-{kind}-seed{seed}-three.png',OUT/f'pbr-{kind}-seed{seed}.png','Baseline v0.7.0',f'Candidate - {kind}')
for size in [7.5,30.]:
    for seed in [0,7]:
        canvas=Image.new('RGB',(1200,430),(20,24,28));d=ImageDraw.Draw(canvas)
        for i,arm in enumerate(["baseline","four","three"]):
            a=Image.open(RAW/f'ortho-{size}-seed{seed}-{arm}.png').convert('RGB').crop((440,160,840,560));x=i*400;canvas.paste(a,(x,30));d.text((x+8,8),arm+' - native pixels',fill='white')
        canvas.save(OUT/f'three-arms-native-{size}-seed{seed}.png')
print(json.dumps({'comparisons':comparisons,'channels':channels,'edges':edges},indent=2))
