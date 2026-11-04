"""Apply the criteria declared before capture; retain failures without changing thresholds."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/brick_atlas_release'
x=json.loads((OUT/'metrics.json').read_text());rows=x['comparisons'];results=[]
for arm in ['two','balanced','three']:
    cases=[]
    for r in [v for v in rows if v['arm']==arm]:
        ref=next(v for v in rows if v['arm']=='four' and v['size']==r['size'] and v['seed']==r['seed']);fail=[]
        for name in ['chroma_periodic_energy_ratio','chroma_correlation_ratio','luma_correlation_ratio']:
            if r[name]>ref[name]+.05:fail.append({'criterion':'noninferiority_'+name,'actual':r[name],'reference':ref[name],'maximum':ref[name]+.05})
        if r['size']==30:
            for name,maximum in [('chroma_periodic_energy_ratio',.5),('chroma_correlation_ratio',.6),('luma_correlation_ratio',.75)]:
                if r[name]>maximum:fail.append({'criterion':'original_distant_'+name,'actual':r[name],'maximum':maximum})
        if r['between_brick_rgb_palette_variance_ratio']<.5:fail.append({'criterion':'palette_variance_floor','actual':r['between_brick_rgb_palette_variance_ratio'],'minimum':.5})
        if abs(r['mean_luminance_ratio']-1)>.1:fail.append({'criterion':'mean_luminance','actual':r['mean_luminance_ratio'],'minimum':.9,'maximum':1.1})
        cases.append({'size':r['size'],'seed':r['seed'],'pass':not fail,'failures':fail})
    results.append({'arm':arm,'strict_gate_pass':all(c['pass'] for c in cases),'cases':cases})
(OUT/'quality-gate.json').write_text(json.dumps(results,indent=2));print(json.dumps(results,indent=2))
