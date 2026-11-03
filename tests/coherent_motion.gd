# Capture matched views for a side-by-side camera loop. Temporary frames live
# outside the repository; set HEX_CAPTURE_DIR to a fresh writable directory.
extends SceneTree

func _initialize() -> void:
	var output := OS.get_environment("HEX_CAPTURE_DIR")
	if output.is_empty():
		push_error("Set HEX_CAPTURE_DIR before running this capture")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer:
			child.visible = false
	demo.set_texture_set(8)
	demo.get_node("DirectionalLight3D").light_energy = 0.9
	demo.get_node("WorldEnvironment").environment.ambient_light_energy = 0.45
	var camera: Camera3D = demo.get_node("Camera3D")
	var mat: ShaderMaterial = demo.get_node("Surface").material_override
	mat.set_shader_parameter("rotation_strength", 0.65)
	mat.set_shader_parameter("blend_contrast", 0.65)
	mat.set_shader_parameter("texture_scale_m", 2.5)
	mat.set_shader_parameter("normal_strength", 0.8)
	mat.set_shader_parameter("use_roughness_map", true)
	for frame in 24:
		var t := float(frame) / 23.0
		camera.position = Vector3(2.0 + t * 2.0, 2.0 + t * 3.0, 6.0 + t * 3.0)
		camera.look_at(Vector3.ZERO, Vector3.UP)
		for mode in ["shared", "paper", "coherent"]:
			mat.set_shader_parameter("paper_blend", mode == "paper")
			mat.set_shader_parameter("coherent_blend", mode == "coherent")
			for delay in 2:
				await process_frame
				await RenderingServer.frame_post_draw
			var error := root.get_texture().get_image().save_png(output.path_join("%s-%02d.png" % [mode, frame]))
			if error != OK:
				push_error("Failed saving motion frame")
				quit(1)
				return
	print("Saved 24 matched camera positions for three modes to ", output)
	quit()
