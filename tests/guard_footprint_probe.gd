# Classifies the actual dominant wall projection derivative at the visible center.
extends SceneTree
func _initialize()->void: call_deferred("run")
func run()->void:
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	var surface:MeshInstance3D=demo.get_node("Surface")
	var wall:=BoxMesh.new()
	wall.size=Vector3(14,8,1)
	surface.mesh=wall
	var mat:ShaderMaterial=surface.material_override
	var shader:=Shader.new()
	shader.code=FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void fragment()")[0].replace('#include "coherent_blend.gdshaderinc"','#include "res://addons/hex_detile/coherent_blend.gdshaderinc"').replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")+"void fragment(){vec3 n=normalize(geometric_world_normal);vec2 st=vec2(axis_sign(n.z)*world_position.x,world_position.y)/texture_scale_m;float footprint=max(length(dFdx(st)*1024.0),length(dFdy(st)*1024.0));ALBEDO=footprint<2.0?vec3(1,0,0):(footprint>8.0?vec3(0,0,1):vec3(0,1,0));}"
	mat.shader=shader
	mat.set_shader_parameter("texture_scale_m",2.5)
	var camera:Camera3D=demo.get_node("Camera3D")
	var records:Array=[]
	for frame_index in [0,1,2,3,4,5,6,23]:
		var z:=1.5*pow(80.0,sin(float(frame_index)/47.0*PI))
		camera.position=Vector3(0.1,0.1,z)
		camera.look_at(Vector3.ZERO,Vector3.UP)
		for frame in 3:
			await process_frame
			await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image()
		var c:=img.get_pixel(img.get_width()/2,img.get_height()/2)
		var classification:String="below2" if c.r>0.9 else ("above8" if c.b>0.9 else "between2and8")
		records.append({"trajectory_frame":frame_index,"camera":[0.1,0.1,z],"center_footprint_texel_class":classification,"pixel_rgb":[c.r,c.g,c.b]})
	print(JSON.stringify(records))
	FileAccess.open("res://docs/guard_optimization/approach-footprints.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	quit(0 if records[0].center_footprint_texel_class=="below2" and records[7].center_footprint_texel_class=="above8" else 1)
