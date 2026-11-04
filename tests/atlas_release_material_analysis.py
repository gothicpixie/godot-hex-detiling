from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
from atlas_metrics import rgb,linear,metrics,labeled_pair
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/brick_atlas_release';RAW=Path('/tmp/brick-atlas-materials')
settings=json.loads((OUT/'material-capture-settings.json').read_text());records=[];comparisons=[];protection=[]
def palette(path,period,material):
    a=linear(rgb(path));h,w=a.shape[:2];xs=(np.arange(w)+.5-w/2)/period;ys=(h/2-np.arange(h)-.5)/period
    region=np.asarray(Image.open(OUT/f'materials/{material}/atlas/atlas-region-ids.png'),dtype=np.int32);alpha=np.asarray(Image.open(ROOT/f'assets/gallery/{material}_albedo_guard.png').convert('RGBA'))[:,:,3];s=alpha.shape[0]
    ix=np.floor(np.mod(xs,4)*s).astype(int);iy=np.floor(np.mod(ys,4)*s).astype(int);ids=region[iy[:,None],ix[None,:]];core=(alpha[iy[:,None]%s,ix[None,:]%s]==255)&(ids>0);n=int(region.max())+1
    keys=ids+n*(np.floor(xs/4).astype(int)[None,:]+100)+n*200*(np.floor(ys/4).astype(int)[:,None]+100);_,inverse=np.unique(keys[core],return_inverse=True);count=np.bincount(inverse);valid=count>=4
    means=np.stack([np.bincount(inverse,weights=a[:,:,c][core])/count for c in range(3)],axis=1)[valid]
    return {'regions':int(valid.sum()),'absolute_between_brick_RGB_variance':float(np.var(means,axis=0).sum()),'absolute_between_brick_chroma_variance':float(np.var(means[:,0]-means[:,1])+np.var(means[:,2]-means[:,1]))}
for r in settings['records']:
    if r['kind']!='ortho':continue
    path=RAW/(r['id']+'.png');m=metrics(path,r['source_repeat_px']);m['palette']=palette(path,r['source_repeat_px'],r['material']);records.append({**r,**m})
for material in ['red_brick','large_red_bricks']:
    for size in [3.,12.]:
        a=next(r for r in records if r['material']==material and r['size_multiplier']==size and r['arm']=='baseline');b=next(r for r in records if r['material']==material and r['size_multiplier']==size and r['arm']=='candidate')
        row={'material':material,'size_multiplier':size,'chroma_energy_ratio':b['mean_normalized_chroma_periodic_energy']/a['mean_normalized_chroma_periodic_energy'],'chroma_correlation_ratio':b['chroma_correlation_mean']/a['chroma_correlation_mean'],'luma_correlation_ratio':b['channels']['luminance']['source_repeat_correlation_mean']/a['channels']['luminance']['source_repeat_correlation_mean'],'palette_variance_ratio':b['palette']['absolute_between_brick_RGB_variance']/a['palette']['absolute_between_brick_RGB_variance'],'mean_luminance_ratio':b['mean_linear_luminance']/a['mean_linear_luminance'],'absolute_baseline_chroma_variance':a['channels']['R-G']['variance']+a['channels']['B-G']['variance'],'absolute_candidate_chroma_variance':b['channels']['R-G']['variance']+b['channels']['B-G']['variance']}
        row['color_metric_informative']=row['absolute_baseline_chroma_variance']>=1e-8
        row['distant_gate_pass']=None if size==3 else row['color_metric_informative'] and row['chroma_energy_ratio']<=.5 and row['chroma_correlation_ratio']<=.6 and row['luma_correlation_ratio']<=.75 and row['palette_variance_ratio']>=.5 and .9<=row['mean_luminance_ratio']<=1.1
        comparisons.append(row)
        labeled_pair(RAW/f'{material}-ortho-{size}-baseline.png',RAW/f'{material}-ortho-{size}-candidate.png',OUT/f'{material}-wall-{size}-native.png','Original - native pixels','Individual - native pixels',(320,160,960,560))
    for shape in ['wall','corner','cylinder']:
        mask=rgb(RAW/f'{material}-{shape}-protected-baseline.png')[:,:,0]==0
        for field in ['rgb','normal','roughness']:
            suffix='' if field=='rgb' else f'-{field}'
            a=np.asarray(Image.open(RAW/f'{material}-{shape}{suffix}-baseline.png').convert('RGB'),dtype=int);b=np.asarray(Image.open(RAW/f'{material}-{shape}{suffix}-candidate.png').convert('RGB'),dtype=int);d=np.abs(a-b)
            protection.append({'material':material,'shape':shape,'field':field,'protected_pixels':int(mask.sum()),'protected_max_byte_delta':int(d[mask].max()) if mask.any() else None,'all_pixel_max_byte_delta':int(d.max())})
        labeled_pair(RAW/f'{material}-{shape}-baseline.png',RAW/f'{material}-{shape}-candidate.png',OUT/f'{material}-{shape}-pbr.png','Original',f'Individual - {shape}')
        if shape=='wall':labeled_pair(RAW/f'{material}-{shape}-baseline.png',RAW/f'{material}-{shape}-candidate.png',OUT/f'{material}-close-native.png','Original - native pixels','Individual - native pixels',(320,160,960,560))
(OUT/'material-metrics.json').write_text(json.dumps({'records':records,'comparisons':comparisons,'protected_channels':protection,'projection_caveat':'Per-projection source phase preservation does not establish globally continuous brick courses on corners/curves.'},indent=2));print(json.dumps({'comparisons':comparisons,'protected_channels':protection},indent=2))
