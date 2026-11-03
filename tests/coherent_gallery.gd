# Reproducible actual GPU captures; run at 960x540 on a graphics display.
extends SceneTree

func _initialize() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer:
			child.visible = false
	demo.get_node("DirectionalLight3D").light_energy = 0.9
	demo.get_node("WorldEnvironment").environment.ambient_light_energy = 0.45
	var surface: MeshInstance3D = demo.get_node("Surface")
	var camera: Camera3D = demo.get_node("Camera3D")
	var mat: ShaderMaterial = surface.material_override
	mat.set_shader_parameter("blend_contrast", 0.65)
	mat.set_shader_parameter("normal_strength", 0.8)
	mat.set_shader_parameter("use_roughness_map", true)
	mat.set_shader_parameter("rotation_strength", 0.65)
	var terrain := surface.mesh
	var wall := BoxMesh.new()
	wall.size = Vector3(14, 8, 1)
	var sphere := SphereMesh.new()
	sphere.radius = 3.4
	sphere.height = 6.8
	sphere.radial_segments = 96
	sphere.rings = 48
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 2.6
	cylinder.bottom_radius = 2.6
	cylinder.height = 6.0
	cylinder.radial_segments = 96
	var cases := [
		{"id":"rocks", "texture":0, "mesh":terrain, "camera":Vector3(0,7,9), "scale":1.5},
		{"id":"sandstone", "texture":1, "mesh":sphere, "camera":Vector3(0,1,12), "scale":1.5},
		{"id":"boulder", "texture":2, "mesh":sphere, "camera":Vector3(0,1,12), "scale":2.5},
		{"id":"brick", "texture":3, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"wood", "texture":4, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"grass", "texture":5, "mesh":terrain, "camera":Vector3(0,7,9), "scale":1.5},
		{"id":"denim", "texture":6, "mesh":sphere, "camera":Vector3(0,1,12), "scale":1.5},
		{"id":"paving", "texture":7, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"cobble", "texture":8, "mesh":terrain, "camera":Vector3(0,7,9), "scale":2.5},
		{"id":"snow", "texture":9, "mesh":terrain, "camera":Vector3(0,7,9), "scale":1.5},
		{"id":"mud", "texture":10, "mesh":terrain, "camera":Vector3(0,7,9), "scale":1.5},
		{"id":"plaster", "texture":11, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"leather", "texture":12, "mesh":cylinder, "camera":Vector3(0,1,12), "scale":1.5},
		{"id":"rubber", "texture":13, "mesh":cylinder, "camera":Vector3(0,1,12), "scale":1.5},
		{"id":"sand", "texture":14, "mesh":terrain, "camera":Vector3(0,7,9), "scale":1.5},
		{"id":"mossy-rock", "texture":15, "mesh":sphere, "camera":Vector3(0,1,12), "scale":2.5},
		{"id":"terrazzo", "texture":16, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"cobble-grazing", "texture":8, "mesh":terrain, "camera":Vector3(9,2,10), "scale":2.5},
		{"id":"cobble-elevated", "texture":8, "mesh":terrain, "camera":Vector3(2,15,10), "scale":2.5},
		{"id":"boulder-oblique", "texture":2, "mesh":sphere, "camera":Vector3(8,4,9), "scale":2.5},
	]
	var metadata: Array = []
	for item in cases:
		metadata.append({"id": item.id, "texture_index": item.texture, "mesh": "terrain" if item.mesh == terrain else "wall" if item.mesh == wall else "sphere" if item.mesh == sphere else "cylinder", "camera_xyz": [item.camera.x, item.camera.y, item.camera.z], "texture_scale_m": item.scale})
		demo.set_texture_set(item.texture)
		surface.mesh = item.mesh
		camera.position = item.camera
		camera.look_at(Vector3.ZERO, Vector3.UP)
		mat.set_shader_parameter("texture_scale_m", item.scale)
		for mode in ["shared", "paper", "coherent"]:
			mat.set_shader_parameter("paper_blend", mode == "paper")
			mat.set_shader_parameter("coherent_blend", mode == "coherent")
			await process_frame
			await RenderingServer.frame_post_draw
			await process_frame
			await RenderingServer.frame_post_draw
			var name: String = item.id + "-" + mode
			var error := root.get_texture().get_image().save_jpg("res://docs/coherent/" + name + ".jpg", 0.94)
			if error != OK:
				push_error("Failed to save " + name)
				quit(1)
				return
			print("Captured ", name)
	var manifest := {"resolution": [root.size.x, root.size.y], "modes": ["shared", "paper", "coherent"], "rotation_strength": 0.65, "blend_contrast": 0.65, "normal_strength": 0.8, "use_roughness_map": true, "directional_light_energy": 0.9, "ambient_light_energy": 0.45, "coherent_filter": true, "detile_detrend": 0.0, "camera_target": [0, 0, 0], "captures": metadata}
	FileAccess.open("res://docs/coherent/capture-settings.json", FileAccess.WRITE).store_string(JSON.stringify(manifest, "\t") + "\n")
	quit()
