"""Install the final addon ZIP into a fresh project; no repository asset dependencies."""
from pathlib import Path
import sys,zipfile,tempfile,subprocess,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/brick_atlas_release'
archive=Path(sys.argv[1]).resolve();fresh=Path(tempfile.mkdtemp(prefix='hex-addon-fresh-'));report={'archive':str(archive),'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'fresh_project':str(fresh)}
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert all(not Path(n).is_absolute() and '..' not in Path(n).parts for n in z.namelist())
    assert all(n.startswith('addons/hex_detile/') for n in z.namelist())
    z.extractall(fresh);report['archive_files']=len(z.namelist());report['crc_pass']=True
report['source_bytes_match']={}
for name in [p.name for p in (fresh/'addons/hex_detile').iterdir() if p.is_file()]:
    p=Path('addons/hex_detile')/name;report['source_bytes_match'][name]=(fresh/p).read_bytes()==(ROOT/p).read_bytes()
assert all(report['source_bytes_match'].values())
(fresh/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Fresh Hex Addon Smoke"\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n[editor_plugins]\nenabled=PackedStringArray("res://addons/hex_detile/plugin.cfg")\n')
shutil.copy2(ROOT/'tests/atlas_release_fresh_smoke.gd',fresh/'fresh-smoke.gd')
for stage,args in [('import',['--headless','--editor','--import']),('runtime',['--always-on-top','--disable-vsync','--disable-render-loop','--resolution','640x360','--script','fresh-smoke.gd'])]:
    r=subprocess.run(['/opt/homebrew/bin/godot','--path',str(fresh),*args],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90);log=r.stdout.decode();(OUT/f'fresh-package-{stage}.log').write_text(log);report[stage+'_exit_code']=r.returncode;report[stage+'_errors']='ERROR:' in log or 'SCRIPT ERROR' in log or 'SHADER ERROR' in log
    assert r.returncode==0 and not report[stage+'_errors'],log[-3000:]
report['runtime_result']=json.loads((fresh/'fresh-smoke-result.json').read_text());assert report['runtime_result']['pass']
shutil.copy2(fresh/'fresh-smoke.png',OUT/'fresh-package-smoke.png');(OUT/'fresh-package-checks.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
