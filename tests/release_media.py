"""Build release previews from actual source bytes and accepted GPU captures."""
from pathlib import Path
import hashlib,json,re,shutil
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/brick_atlas_release'
def font(size):
    try:return ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',size)
    except OSError:return ImageFont.load_default()
text=(ROOT/'demo.gd').read_text()
names=re.findall(r'"([^"\n]+)"',text.split('const TEXTURE_NAMES := [',1)[1].split(']\n',1)[0])
sources=re.findall(r'\["(res://[^"\n]+)"',text.split('const TEXTURE_SETS := [',1)[1].split(']\n',1)[0])
assert len(names)==len(sources)==19
columns,cell,patch,rowheight=7,164,144,202
canvas=Image.new('RGB',(columns*cell,68+3*rowheight),'#182127');draw=ImageDraw.Draw(canvas)
draw.text((12,9),'19 source albedo textures — not shader renders',font=font(23),fill='#f1eee6')
draw.text((12,40),'Original images reduced for preview; no color adjustment. New Red/Large Red are authoring examples.',font=font(15),fill='#c7d2cf')
records=[]
for i,(name,source) in enumerate(zip(names,sources)):
    p=ROOT/source.removeprefix('res://');im=Image.open(p).convert('RGB');x=i%columns*cell+10;y=68+i//columns*rowheight
    canvas.paste(im.resize((patch,patch),Image.Resampling.LANCZOS),(x,y))
    lines=[];line=''
    for word in name.split():
        trial=(line+' '+word).strip()
        if draw.textlength(trial,font=font(15))>patch and line:lines.append(line);line=word
        else:line=trial
    lines.append(line);draw.multiline_text((x,y+patch+5),'\n'.join(lines),font=font(15),fill='#f1eee6',spacing=2)
    records.append({'index':i,'name':name,'source':source,'size':list(im.size),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
canvas.save(OUT/'source-albedo-palette-19.png')
accepted=ROOT/'docs/individual_brick/distant-native-seed0.png'
shutil.copyfile(accepted,OUT/'brick4-accepted-native.png')
im=Image.open(accepted).convert('RGB');assert im.size==(1280,430)
preview=Image.new('RGB',(1280,640),'#182127');d=ImageDraw.Draw(preview)
d.text((24,12),'Brick 4: source-aligned palette variation',font=font(32),fill='#f1eee6')
d.text((24,55),'Actual matched shader renders — original left, accepted 4×4 mode right',font=font(20),fill='#c7d2cf')
preview.paste(im,(0,92))
d.text((24,550),'Opt-in prepared material; original joint shapes and some protected rims still repeat.',font=font(21),fill='#f1eee6')
d.text((24,589),'Atlas: ~85.3 MiB theoretical uncompressed RGBA8 texels including mipmaps; not measured VRAM.',font=font(19),fill='#c7d2cf')
preview.save(OUT/'store-preview.png')
(OUT/'media-provenance.json').write_text(json.dumps({'source_preview':records,'source_preview_resampling':'Lanczos144px; no color adjustment','accepted_render_source':str(accepted.relative_to(ROOT)),'accepted_render_sha256':hashlib.sha256(accepted.read_bytes()).hexdigest(),'accepted_render_resampling':'none; PNG copied byte-for-byte','compatibility_evidence':'controls.json: current N4 matches accepted 0f5322a','store_preview':'accepted native image pasted without scaling; text added'},indent=2)+'\n')
print('Generated 19-source preview and accepted-render release preview from actual assets')
