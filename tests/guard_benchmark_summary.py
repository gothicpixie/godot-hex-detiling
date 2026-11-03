"""Report median-of-round-medians and ranges, preserving uncertainty."""
from pathlib import Path
from statistics import median
import json
root=Path(__file__).resolve().parents[1]
out=root/'docs/guard_optimization'
data=json.loads((out/'benchmark.json').read_text())
assert len(data['records'])==36
assert all(r['frame_post_draw_callbacks']==600 and r['draw_calls_in_frame']>0 for r in data['records'])
rows=[]
for scene in ['terrain','close-wall','distant']:
    base=median(r['median_draw_call_ms'] for r in data['records'] if r['scene']==scene and r['variant']=='frozen')
    for variant in ['frozen','pack','early','both']:
        vals=[r['median_draw_call_ms'] for r in data['records'] if r['scene']==scene and r['variant']==variant]
        rows.append({'scene':scene,'variant':variant,'median_of_round_medians_ms':median(vals),'min_round_median_ms':min(vals),'max_round_median_ms':max(vals),'round_medians_ms':vals,'relative_to_frozen':median(vals)/base})
(out/'benchmark-summary.json').write_text(json.dumps(rows,indent=2))
print('| Scene | Arm | Median ms | Round range ms | Change vs frozen |')
print('|---|---|---:|---:|---:|')
for r in rows:
    print(f"|{r['scene']}|{r['variant']}|{r['median_of_round_medians_ms']:.3f}|{r['min_round_median_ms']:.3f}–{r['max_round_median_ms']:.3f}|{(r['relative_to_frozen']-1)*100:+.1f}%|")
