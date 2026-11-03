from pathlib import Path
from PIL import Image,ImageDraw
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/individual_brick';RAW=Path('/tmp/individual-brick-evaluation')
settings=json.loads((OUT/'motion-settings.json').read_text())
for trajectory in ['approach','pan']:
    for seed in ([0] if trajectory=='approach' else [7]):
        frames=[]
        for i in range(16):
            canvas=Image.new('RGB',(1280,390),(20,24,28));d=ImageDraw.Draw(canvas)
            for j,arm in enumerate(['baseline','individual']):
                image=Image.open(RAW/f'{trajectory}-seed{seed}-{arm}-{i:02}.png').convert('RGB');canvas.paste(image,(640*j,30));d.text((640*j+8,8),f'{arm} - actual {trajectory} motion - seed {seed} - frame {i+1}/16',fill='white')
            frames.append(canvas)
        frames[0].save(OUT/f'{trajectory}-seed{seed}-motion.gif',save_all=True,append_images=frames[1:],duration=160,loop=0,optimize=True)
print('Two representative matched actual-motion GIFs; raw moving image differences are not used as flicker metrics.')

pairs={}
for r in settings['records']:
    key=(r['trajectory'],r['seed'],r['frame']);pairs.setdefault(key,{})[r['arm']]=r
assert len(pairs)==64 and all(set(p)=={'baseline','individual'} for p in pairs.values())
maximum=max(max(abs(a-b) for a,b in zip(p['baseline']['camera'],p['individual']['camera'])) for p in pairs.values())
assert maximum<1e-8
(OUT/'motion-pair-audit.json').write_text(json.dumps({'matched_camera_poses':64,'maximum_camera_position_difference':maximum,'trajectories':['approach','pan'],'seed_cases':'atlas0/hash0 and atlas7/hash7','moving_frame_difference_is_not_used_as_flicker':True},indent=2))
