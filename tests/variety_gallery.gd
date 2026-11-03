# Capture paired periodic, offset-only, and rotated results on six materials.
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
	mat.set_shader_parameter("use_roughness_map", true)
	var terrain := surface.mesh
	var wall := BoxMesh.new()
	wall.size = Vector3(14, 8, 1)
	var sphere := SphereMesh.new()
	sphere.radius = 3.4
	sphere.height = 6.8
	sphere.radial_segments = 96
	sphere.rings = 48
	var cases := [
		{"id":"brick", "texture":3, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"wood", "texture":4, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"grass", "texture":5, "mesh":terrain, "camera":Vector3(0,7,9), "scale":1.5},
		{"id":"denim", "texture":6, "mesh":sphere, "camera":Vector3(0,1,12), "scale":1.5},
		{"id":"paving", "texture":7, "mesh":wall, "camera":Vector3(1,1,13), "scale":2.5},
		{"id":"cobble", "texture":8, "mesh":terrain, "camera":Vector3(0,7,9), "scale":2.5},
	]
	for item in cases:
		demo.set_texture_set(item.texture)
		surface.mesh = item.mesh
		camera.position = item.camera
		camera.look_at(Vector3.ZERO, Vector3.UP)
		mat.set_shader_parameter("texture_scale_m", item.scale)
		for mode in ["periodic", "offset", "rotated"]:
			demo.set_detile(mode != "periodic")
			mat.set_shader_parameter("rotation_strength", 0.65 if mode == "rotated" else 0.0)
			await process_frame
			await process_frame
			await create_timer(0.5).timeout
			var name: String = item.id + "-" + mode
			var error := root.get_texture().get_image().save_jpg("res://docs/variety/" + name + ".jpg", 0.92)
			if error != OK:
				push_error("Failed to save " + name)
				quit(1)
				return
			print("Captured ", name)
	quit()
