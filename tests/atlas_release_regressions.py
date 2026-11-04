from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[1]
out=root/'docs/brick_atlas_release'
records=[]
for script in ['atlas_release_smoke','atlas_release_material_smoke','atlas_release_ui_state','individual_brick_smoke','distant_brick_smoke','smoke','gpu_probe','coherent_probe','structure_smoke','structure_probe','brick_guard_smoke','brick_guard_probe','brick_guard_baseline']:
    try:
        result=subprocess.run(['/opt/homebrew/bin/godot','--path','.', '--always-on-top','--disable-vsync','--resolution','640x360','--script',f'tests/{script}.gd'],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
        text=result.stdout.decode();(out/f'regression-{script}.log').write_text(text)
        ok=result.returncode==0 and 'FAIL:' not in text and 'SCRIPT ERROR' not in text and 'SKIP:' not in text
        records.append({'script':script,'exit_code':result.returncode,'pass':ok})
    except subprocess.TimeoutExpired as e:
        (out/f'regression-{script}.log').write_bytes(e.stdout or b'');records.append({'script':script,'timeout':True,'pass':False})
    print(records[-1],flush=True)
(out/'regressions.json').write_text(json.dumps(records,indent=2))
