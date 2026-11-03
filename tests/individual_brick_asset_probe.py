"""Independent native atlas audit, including palette and fine-detail retention."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/individual_brick'
def lin(a):
    a=a.astype(np.float32)/255
    return np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4)
source=np.asarray(Image.open(ROOT/'assets/gallery/brick_4_albedo_guard.png').convert('RGBA'))
labels=np.asarray(Image.open(OUT/'atlas-region-ids.png'),dtype=np.int32)
N=int(labels.max())+1
results=[]
for seed in [0,7]:
    atlas=np.asarray(Image.open(ROOT/f'assets/gallery/brick_4_individual_atlas_seed{seed}.png').convert('RGBA'))
    sums=[np.zeros((N,3)),np.zeros((N,3))];hp=[np.zeros(N),np.zeros(N)];counts=np.zeros(N);alpha_bad=0;protected_bad=0;protected_count=0
    for start in range(0,4096,128):
        end=min(start+128,4096);ys=np.arange(start,end);base=np.tile(source[ys%1024],(1,4,1));out=atlas[start:end];lab=labels[start:end];core=(base[:,:,3]==255)&(lab>0)
        alpha_bad+=int(np.count_nonzero(base[:,:,3]!=out[:,:,3]));protected=base[:,:,3]==0;protected_count+=int(protected.sum());protected_bad+=int(np.count_nonzero(np.any(base[:,:,:3]!=out[:,:,:3],axis=2)&protected))
        ids=lab[core];counts+=np.bincount(ids,minlength=N)
        # Halo rows make the highpass comparison independent of chunk boundaries.
        padded_y=np.arange(start-8,end+8)%4096
        arrays=[np.tile(source[padded_y%1024,:,:3],(1,4,1)),atlas[padded_y,:,:3]]
        for arm,array in enumerate(arrays):
            l=lin(array);center=l[8:-8]
            for c in range(3):sums[arm][:,c]+=np.bincount(ids,weights=center[:,:,c][core],minlength=N)
            y=l@np.array([.2126,.7152,.0722],dtype=np.float32);fine=(y-gaussian_filter(y,2,mode='wrap'))[8:-8]
            hp[arm]+=np.bincount(ids,weights=fine[core]**2,minlength=N)
    valid=counts>100;means=[s[valid]/counts[valid,None] for s in sums];palette=[float(np.var(a,axis=0).sum()) for a in means]
    chroma=[float(np.var(a[:,0]-a[:,1])+np.var(a[:,2]-a[:,1])) for a in means]
    weights=np.array([.2126,.7152,.0722]);mean_l=[a@weights for a in means];fine=[np.sqrt(h[valid]/counts[valid])/(m+1e-9) for h,m in zip(hp,mean_l)]
    ratio=fine[1]/np.maximum(fine[0],1e-9)
    results.append({'seed':seed,'actual_regions_with_core':int(valid.sum()),'alpha_bad_pixels':alpha_bad,'protected_rgb_bad_pixels':protected_bad,'protected_pixels_checked':protected_count,'between_brick_linear_rgb_variance_source':palette[0],'between_brick_linear_rgb_variance_atlas':palette[1],'palette_variance_ratio':palette[1]/palette[0],'between_brick_opponent_chroma_variance_ratio':chroma[1]/chroma[0],'median_relative_fine_detail_contrast_ratio':float(np.median(ratio)),'p05_relative_fine_detail_contrast_ratio':float(np.percentile(ratio,5)),'mean_core_luminance_ratio':float(mean_l[1].mean()/mean_l[0].mean()),'definition':'region means across alpha255 cores; between-region RGB variance=sum channel population variances; fine detail=Gaussian sigma2 native-pixel highpass luminance RMS divided by region mean luminance, per-region median'})
(OUT/'asset-audit.json').write_text(json.dumps(results,indent=2));print(json.dumps(results,indent=2))
