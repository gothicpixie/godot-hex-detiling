# Fixed world positions with changing pixel footprint; no moving-image differencing.
extends SceneTree
var mat:ShaderMaterial
var vp:SubViewport
func _initialize()->void: call_deferred("run")
func run()->void:
	var code:=FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void vertex()")[0].replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string("res://addons/hex_detile/coherent_blend.gdshaderinc")).replace("shader_type spatial;","shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
	assert(not "TIME" in code)
	var shader:=Shader.new()
	shader.code=code+"uniform float probe_footprint=0.0; void fragment(){vec3 p=vec3(UV*vec2(100,70)-vec2(50,35),0.5);float gain=brick_macro_gain(p,vec3(probe_footprint,0,0),vec3(0,probe_footprint,0));COLOR=vec4(vec3(0.5+(gain-1.0)*2.0),1);}"
	vp=SubViewport.new()
	vp.size=Vector2i(128,128)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rect:=ColorRect.new()
	rect.size=Vector2(128,128)
	vp.add_child(rect)
	mat=ShaderMaterial.new()
	mat.shader=shader
	rect.material=mat
	mat.set_shader_parameter("texture_scale_m",2.5)
	mat.set_shader_parameter("brick_macro_strength",0.18)
	var records:Array=[]
	for seed in [0.0,7.0]:
		mat.set_shader_parameter("variation_seed",seed)
		var previous:=PackedByteArray()
		for frame in 16:
			var t:=float(frame)/15.0
			var distance:=1.5*pow(40.0,sin(t*PI))
			var footprint:=2.0*(distance-0.5)*tan(deg_to_rad(52.0)*0.5)/360.0
			mat.set_shader_parameter("probe_footprint",footprint)
			await process_frame
			RenderingServer.force_draw(false)
			var bytes:=vp.get_texture().get_image().get_data()
			var maximum:=0
			if not previous.is_empty():
				for i in bytes.size(): maximum=maxi(maximum,absi(int(bytes[i])-int(previous[i])))
			records.append({"seed":seed,"frame":frame,"world_pixel_footprint":footprint,"max_fixed_world_gain_increment_quantized":float(maximum)/(255.0*2.0)})
			previous=bytes
	FileAccess.open("res://docs/distant_brick/world-stability.json",FileAccess.WRITE).store_string(JSON.stringify({"probe":"16384 fixed world points across100x70m wall; only pixel derivatives change along captured approach; shader gain amplified2 beforeRGBA8","quantization_gain":1.0/510.0,"no_TIME_in_source":true,"records":records},"\t"))
	print("Fixed-world macro footprint probe complete")
	quit()
