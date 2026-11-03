# Native captures: identical camera/light/settings for each mode and seed.
extends SceneTree
func _initialize()->void: call_deferred("run")
func run()->void:
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	demo.set_texture_set(3)
	demo.set_structure(true)
	demo.get_node("DirectionalLight3D").light_energy=0.9
	demo.get_node("WorldEnvironment").environment.ambient_light_energy=0.45
	var surface:MeshInstance3D=demo.get_node("Surface")
	var camera:Camera3D=demo.get_node("Camera3D")
	var mat:ShaderMaterial=surface.material_override
	var terrain:Mesh=surface.mesh
	var wall:=BoxMesh.new()
	wall.size=Vector3(14,8,1)
	var records:Array=[]
	for seed in [0.0,7.0]:
		for view in [{"id":"wall","position":Vector3(1,1,10),"mesh":wall},{"id":"oblique","position":Vector3(7,3,9),"mesh":wall},{"id":"elevated","position":Vector3(2,12,8),"mesh":terrain}]:
			surface.mesh=view.mesh
			camera.position=view.position
			camera.look_at(Vector3.ZERO,Vector3.UP)
			for mode in ["periodic","structured","guarded"]:
				mat.set_shader_parameter("structure_enabled",true)
				mat.set_shader_parameter("structure_guard_enabled",mode=="guarded")
				mat.set_shader_parameter("structure_guard_map",load("res://assets/gallery/brick_4_interior_mask.png"))
				mat.set_shader_parameter("detile_enabled",mode!="periodic")
				mat.set_shader_parameter("coherent_blend",true)
				mat.set_shader_parameter("paper_blend",false)
				mat.set_shader_parameter("rotation_strength",0.0)
				mat.set_shader_parameter("variation_seed",seed)
				mat.set_shader_parameter("texture_scale_m",2.5)
				mat.set_shader_parameter("normal_strength",0.8)
				mat.set_shader_parameter("use_roughness_map",true)
				mat.set_shader_parameter("blend_contrast",0.65)
				mat.set_shader_parameter("detile_detrend",0.0)
				for frame in 4:
					await process_frame
					await RenderingServer.frame_post_draw
				var id:String="brick-"+view.id+"-seed"+str(int(seed))+"-"+mode
				root.get_texture().get_image().save_png("res://docs/brick_guard/"+id+".png")
				print("Captured ",id)
				records.append({"id":id,"camera":[view.position.x,view.position.y,view.position.z],"seed":seed,"mode":mode})
	FileAccess.open("res://docs/brick_guard/capture-settings.json",FileAccess.WRITE).store_string(JSON.stringify({"resolution":[root.size.x,root.size.y],"camera_target":[0,0,0],"light_energy":0.9,"ambient_energy":0.45,"normal_strength":0.8,"texture_scale_m":2.5,"blend_contrast":0.65,"detile_detrend":0.0,"captures":records},"\t"))
	quit()
