# Reproduce the paired gallery captures in docs/gallery/ on a GPU-backed display.
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
	mat.set_shader_parameter("rotation_strength", 0.65)
	mat.set_shader_parameter("blend_contrast", 0.65)
	mat.set_shader_parameter("use_roughness_map", true)
	mat.set_shader_parameter("texture_scale_m", 1.5)
	var terrain := surface.mesh
	var sphere := SphereMesh.new()
	sphere.radius = 3.4
	sphere.height = 6.8
	sphere.radial_segments = 96
	sphere.rings = 48
	var wall := BoxMesh.new()
	wall.size = Vector3(14, 8, 1)
	var cases := [
		{"id": "rocks-terrain", "texture": 0, "mesh": terrain, "camera": Vector3(0, 7, 9)},
		{"id": "sandstone-sphere", "texture": 1, "mesh": sphere, "camera": Vector3(0, 1, 12)},
		{"id": "boulder-wall", "texture": 2, "mesh": wall, "camera": Vector3(1, 1, 13)},
		{"id": "boulder-sphere", "texture": 2, "mesh": sphere, "camera": Vector3(0, 1, 12)},
	]
	for item in cases:
		demo.set_texture_set(item.texture)
		mat.set_shader_parameter("texture_scale_m", 2.5 if item.texture == 2 else 1.5)
		surface.mesh = item.mesh
		camera.position = item.camera
		camera.look_at(Vector3.ZERO, Vector3.UP)
		for enabled in [false, true]:
			demo.set_detile(enabled)
			await process_frame
			await process_frame
			await create_timer(0.6).timeout
			var name: String = item.id + ("-detiled" if enabled else "-periodic")
			var error := root.get_texture().get_image().save_png("res://docs/gallery/" + name + ".png")
			if error != OK:
				push_error("Failed to save " + name)
				quit(1)
				return
			print("Captured ", name)
	quit()
