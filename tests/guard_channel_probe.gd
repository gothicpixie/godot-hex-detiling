# Actual production helper color/normal/roughness independently, RGBA8 readback.
extends SceneTree
const OUT="res://docs/guard_optimization/"
var vp:SubViewport
var mat:ShaderMaterial
var prefixes:Dictionary={}
var records:Array=[]
var failures:=0
func _initialize()->void: call_deferred("run")
func run()->void:
	for mode in ["frozen","packed","separate"]:
		var frozen:bool=mode=="frozen"
		var shader_path:String=OUT+"fixtures/v0.6.0.gdshader" if frozen else "res://addons/hex_detile/hex_detile.gdshader"
		var include_path:String=OUT+"fixtures/v0.6.0.gdshaderinc" if frozen else "res://addons/hex_detile/coherent_blend.gdshaderinc"
		prefixes[mode]=FileAccess.get_file_as_string(shader_path).split("void vertex()")[0].replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string(include_path)).replace("shader_type spatial;","shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
	vp=SubViewport.new()
	vp.size=Vector2i(128,128)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rect:=ColorRect.new()
	rect.size=Vector2(128,128)
	vp.add_child(rect)
	mat=ShaderMaterial.new()
	rect.material=mat
	for key in {"structure_enabled":true,"structure_guard_enabled":true,"detile_enabled":true,"coherent_blend":true,"structure_period":Vector2(2.0/15.0,1.0/14.0),"structure_stagger":0.5,"normal_strength":0.8,"use_roughness_map":true,"coherent_filter":true}:
		mat.set_shader_parameter(key,{"structure_enabled":true,"structure_guard_enabled":true,"detile_enabled":true,"coherent_blend":true,"structure_period":Vector2(2.0/15.0,1.0/14.0),"structure_stagger":0.5,"normal_strength":0.8,"use_roughness_map":true,"coherent_filter":true}[key])
	mat.set_shader_parameter("normal_map",load("res://assets/gallery/brick_4_normal.jpg"))
	mat.set_shader_parameter("roughness_map",load("res://assets/gallery/brick_4_roughness.jpg"))
	mat.set_shader_parameter("structure_guard_map",load("res://assets/gallery/brick_4_interior_mask.png"))
	for footprint in [0.25,2.0,3.5,7.99,8.0,12.0]:
		for seed in [0.0,7.0]:
			mat.set_shader_parameter("variation_seed",seed)
			for settings in [{"maps":true,"detrend":0.0},{"maps":false,"detrend":0.6}]:
				mat.set_shader_parameter("normal_strength",0.8 if settings.maps else 0.0)
				mat.set_shader_parameter("use_roughness_map",settings.maps)
				mat.set_shader_parameter("detile_detrend",settings.detrend)
				for channel in ["color","normal","roughness"]:
					var reference:=await render("frozen",footprint,channel)
					for mode in ["packed","separate"]:
						var candidate:=await render(mode,footprint,channel)
						var maximum:=0
						var a:=reference.get_data()
						var b:=candidate.get_data()
						for i in a.size(): maximum=maxi(maximum,absi(int(a[i])-int(b[i])))
						var ok:=maximum<=2
						if not ok: failures+=1
						var row:={"mode":mode,"footprint_texels":footprint,"seed":seed,"maps":settings.maps,"detrend":settings.detrend,"channel":channel,"max_byte_delta":maximum,"pass":ok}
						records.append(row)
						print(JSON.stringify(row))
	FileAccess.open(OUT+"channels.json",FileAccess.WRITE).store_string(JSON.stringify({"readback":"RGBA8 (Compatibility does not expose floating canvas readback)","max_byte_tolerance":2,"records":records,"failures":failures},"\t"))
	quit(1 if failures else 0)
func render(mode:String,footprint:float,channel:String)->Image:
	var shader:=Shader.new()
	var result:String="c" if channel=="color" else ("n*0.5+0.5" if channel=="normal" else "vec3(r)")
	shader.code=prefixes[mode]+"\nvoid fragment(){vec2 p=UV*2.0-vec2(0.17,0.31);vec2 dx=vec2("+str(footprint/1024.0)+",0);vec2 dy=vec2(0,"+str(footprint/16384.0)+");vec3 c;vec3 n;float r;coherent_sample_material(p,dx,dy,c,n,r);COLOR=vec4("+result+",1);}"
	mat.shader=shader
	mat.set_shader_parameter("structure_guard_in_albedo_alpha",mode=="packed")
	mat.set_shader_parameter("albedo_map",load("res://assets/gallery/brick_4_albedo_guard.png" if mode=="packed" else "res://assets/gallery/brick_4_albedo.jpg"))
	for frame in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	return vp.get_texture().get_image()
