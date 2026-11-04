from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from scipy.ndimage import gaussian_filter

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

def labeled_pair(a,b,path,labela,labelb,crop=None):
    a=Image.open(a).convert('RGB');b=Image.open(b).convert('RGB')
    if crop: a=a.crop(crop);b=b.crop(crop)
    else:a=a.resize((640,360));b=b.resize((640,360))
    canvas=Image.new('RGB',(a.width+b.width,a.height+30),(20,24,28));canvas.paste(a,(0,30));canvas.paste(b,(a.width,30));d=ImageDraw.Draw(canvas);d.text((8,8),labela,fill='white');d.text((a.width+8,8),labelb,fill='white');canvas.save(path)
