extends SceneTree
const OUT="res://docs/distant_brick/"
const RAW="/tmp/distant-brick-evaluation/"
var demo:Node
var mat:ShaderMaterial
var camera:Camera3D
var shaders:Dictionary={}
var records:Array=[]
func _initialize()->void: call_deferred("run")
func source(frozen:bool)->String:
	var shader_path:String=OUT+"fixtures/v0.7.0.gdshader" if frozen else "res://addons/hex_detile/hex_detile.gdshader"
	var include_path:String=OUT+"fixtures/v0.7.0.gdshaderinc" if frozen else "res://addons/hex_detile/coherent_blend.gdshaderinc"
	return FileAccess.get_file_as_string(shader_path).replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string(include_path))
func compiled(code:String)->Shader:
	var shader:=Shader.new()
	shader.code=code
	return shader
func mode(arm:String,unlit:bool=false,diagnostic:String="")->void:
	var code:String=source(arm=="baseline")
	if unlit or not diagnostic.is_empty(): code=code.replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
	if not diagnostic.is_empty():
		var last:=code.rfind("}")
		var expression:String="NORMAL*0.5+0.5" if diagnostic=="normal" else ("vec3(ROUGHNESS)" if diagnostic=="roughness" else "vec3(textureGrad(structure_guard_map,vec2(world_position.x,world_position.y)/texture_scale_m,dFdx(vec2(world_position.x,world_position.y)/texture_scale_m),dFdy(vec2(world_position.x,world_position.y)/texture_scale_m)).r)")
		code=code.substr(0,last)+"ALBEDO="+expression+";\n"+code.substr(last)
	mat.shader=compiled(code)
	mat.set_shader_parameter("brick_macro_enabled",arm=="macro" or arm=="both")
	mat.set_shader_parameter("albedo_map",load("res://assets/gallery/brick_4_albedo_guard_normalized.png" if arm=="normalization" or arm=="both" else "res://assets/gallery/brick_4_albedo_guard.png"))
func pose(p:Vector3)->void:
	camera.position=p
	camera.look_at(Vector3.ZERO,Vector3.UP)
func capture()->Image:
	for frame in 2:
		await process_frame
		RenderingServer.force_draw(false)
	return root.get_texture().get_image()
func run()->void:
	DirAccess.make_dir_recursive_absolute(RAW)
	demo=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	demo.set_texture_set(3)
	demo.set_structure(true)
	var surface:MeshInstance3D=demo.get_node("Surface")
	var wall:=BoxMesh.new()
	wall.size=Vector3(160,100,1)
	surface.mesh=wall
	camera=demo.get_node("Camera3D")
	mat=surface.material_override
	for key in {"coherent_blend":true,"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"blend_contrast":0.65,"detile_detrend":0.0}:
		mat.set_shader_parameter(key,{"coherent_blend":true,"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"blend_contrast":0.65,"detile_detrend":0.0}[key])
	mat.set_shader_parameter("structure_guard_map",load("res://assets/gallery/brick_4_interior_mask.png"))
	if "--controls" in OS.get_cmdline_user_args():
		await controls()
	elif "--motion" in OS.get_cmdline_user_args():
		await motion()
	else:
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		pose(Vector3(0,0,40))
		for distance in [7.5,30.0]:
			camera.size=distance
			var center:=camera.unproject_position(Vector3(0,0,0.5))
			var x:=camera.unproject_position(Vector3(2.5,0,0.5))
			var y:=camera.unproject_position(Vector3(0,2.5,0.5))
			for seed in [0.0,7.0]:
				mat.set_shader_parameter("variation_seed",seed)
				for arm in ["baseline","normalization","macro","both"]:
					mode(arm,true)
					var image:=await capture()
					var id:String="ortho-"+str(distance)+"-seed"+str(int(seed))+"-"+arm
					image.save_png(RAW+id+".png")
					records.append({"id":id,"kind":"ortho","size":distance,"seed":seed,"arm":arm,"repeat_px":[absf(x.x-center.x),absf(y.y-center.y)]})
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		for view in [{"id":"close","p":Vector3(0.1,0.1,2)},{"id":"grazing","p":Vector3(9,1,2)},{"id":"distant","p":Vector3(1,1,32)}]:
			pose(view.p)
			for seed in [0.0,7.0]:
				mat.set_shader_parameter("variation_seed",seed)
				for arm in ["baseline","both"]:
					mode(arm)
					var image:=await capture()
					var id:String="pbr-"+view.id+"-seed"+str(int(seed))+"-"+arm
					image.save_png(RAW+id+".png")
					records.append({"id":id,"kind":"pbr","view":view.id,"seed":seed,"arm":arm,"camera":[camera.position.x,camera.position.y,camera.position.z]})
				for channel in ["normal","roughness","mask"]:
					for arm in ["baseline","both"]:
						if channel=="mask" and arm=="both": continue
						mode(arm,true,channel)
						var image:=await capture()
						image.save_png(RAW+"channel-"+view.id+"-seed"+str(int(seed))+"-"+channel+"-"+arm+".png")
	FileAccess.open(OUT+("controls.json" if "--controls" in OS.get_cmdline_user_args() else ("motion-settings.json" if "--motion" in OS.get_cmdline_user_args() else "capture-settings.json")),FileAccess.WRITE).store_string(JSON.stringify({"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"resolution":[root.size.x,root.size.y],"records":records},"\t"))
	print("Captured ",records.size()," cases")
	quit()
func motion()->void:
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	for trajectory in ["approach","pan"]:
		for seed in [0.0,7.0]:
			mat.set_shader_parameter("variation_seed",seed)
			for frame in 16:
				var t:=float(frame)/15.0
				if trajectory=="approach": pose(Vector3(0.1,0.1,1.5*pow(40.0,sin(t*PI))))
				else: pose(Vector3(-8+16*t,0.4,30))
				for arm in ["baseline","both"]:
					mode(arm)
					var image:=await capture()
					var id:String=trajectory+"-seed"+str(int(seed))+"-"+arm+"-%02d"%frame
					image.save_png(RAW+id+".png")
					records.append({"id":id,"trajectory":trajectory,"seed":seed,"arm":arm,"frame":frame,"camera":[camera.position.x,camera.position.y,camera.position.z]})

func controls()->void:
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	pose(Vector3(0.1,0.1,2))
	mode("baseline")
	var a:PackedByteArray=(await capture()).get_data()
	for arm in ["off","zero"]:
		mode(arm)
		mat.set_shader_parameter("brick_macro_enabled",arm=="zero")
		mat.set_shader_parameter("brick_macro_strength",0.0 if arm=="zero" else 0.18)
		var b:PackedByteArray=(await capture()).get_data()
		var maximum:=0
		for i in a.size(): maximum=maxi(maximum,absi(int(a[i])-int(b[i])))
		records.append({"control":arm,"max_byte_delta_to_frozen":maximum})
