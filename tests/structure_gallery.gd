# Matched actual GPU screenshots; no image adjustments. Production demo presets.
extends SceneTree
func _initialize() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	demo.get_node("DirectionalLight3D").light_energy=0.9
	demo.get_node("WorldEnvironment").environment.ambient_light_energy=0.45
	var surface: MeshInstance3D=demo.get_node("Surface")
	var camera: Camera3D=demo.get_node("Camera3D")
	var mat: ShaderMaterial=surface.material_override
	var terrain=surface.mesh
	var wall:=BoxMesh.new()
	wall.size=Vector3(14,8,1)
	var metadata:Array=[]
	for item in [{"id":"brick","index":3},{"id":"wood","index":4},{"id":"paving","index":7}]:
		demo.set_texture_set(item.index)
		demo.set_structure(true)
		var period:Vector2=mat.get_shader_parameter("structure_period")
		var stagger:float=mat.get_shader_parameter("structure_stagger")
		for view in [{"id":"wall","position":Vector3(1,1,13),"mesh":wall},{"id":"oblique","position":Vector3(7,3,9),"mesh":wall},{"id":"elevated","position":Vector3(2,12,8),"mesh":terrain}]:
			surface.mesh=view.mesh
			camera.position=view.position
			camera.look_at(Vector3.ZERO,Vector3.UP)
			for mode in ["periodic","offset","rotated","structured"]:
				# Set uniforms explicitly after preset toggles to keep all comparisons matched.
				mat.set_shader_parameter("structure_enabled",mode=="structured")
				mat.set_shader_parameter("detile_enabled",mode!="periodic")
				mat.set_shader_parameter("coherent_blend",true)
				mat.set_shader_parameter("paper_blend",false)
				mat.set_shader_parameter("rotation_strength",1.0 if mode=="rotated" else 0.0)
				mat.set_shader_parameter("variation_seed",0.0)
				mat.set_shader_parameter("texture_scale_m",2.5)
				mat.set_shader_parameter("normal_strength",0.8)
				mat.set_shader_parameter("use_roughness_map",true)
				mat.set_shader_parameter("blend_contrast",0.65)
				mat.set_shader_parameter("detile_detrend",0.0)
				for delay in 3:
					await process_frame
					await RenderingServer.frame_post_draw
				var name:String=item.id+"-"+view.id+"-"+mode
				var error:=root.get_texture().get_image().save_png("res://docs/structure/"+name+".png")
				if error!=OK:
					push_error("Could not save "+name)
					quit(1)
					return
				print("Captured ",name)
				metadata.append({"id":name,"texture_index":item.index,"camera":[view.position.x,view.position.y,view.position.z],"period":[period.x,period.y],"stagger":stagger,"rotation_strength":1 if mode=="rotated" else 0})
	FileAccess.open("res://docs/structure/capture-settings.json",FileAccess.WRITE).store_string(JSON.stringify({"resolution":[root.size.x,root.size.y],"camera_target":[0,0,0],"light_energy":0.9,"ambient_energy":0.45,"normal_strength":0.8,"texture_scale_m":2.5,"seed":0,"coherent_filter":true,"blend_contrast":0.65,"detile_detrend":0.0,"captures":metadata},"\t")+"\n")
	quit()
