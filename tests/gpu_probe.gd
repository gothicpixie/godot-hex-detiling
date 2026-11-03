extends SceneTree
func _initialize() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	var material: ShaderMaterial = demo.get_node("Surface").material_override
	var flat := Image.create(8, 8, false, Image.FORMAT_RGBAF)
	flat.fill(Color(0.5, 0.5, 1.0, 1.0))
	material.set_shader_parameter("normal_map", ImageTexture.create_from_image(flat))
	material.set_shader_parameter("rotation_strength", 1.0)
	material.set_shader_parameter("normal_strength", 0.0)
	await create_timer(1.0).timeout
	var baseline := root.get_texture().get_image()
	baseline.save_png("user://flat-zero.png")
	material.set_shader_parameter("normal_strength", 1.0)
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	var rotated := root.get_texture().get_image()
	rotated.save_png("user://flat-full.png")
	var max_difference := 0.0
	for y in range(0, baseline.get_height(), 2):
		for x in range(0, baseline.get_width(), 2):
			var a := baseline.get_pixel(x, y)
			var b := rotated.get_pixel(x, y)
			max_difference = maxf(max_difference, maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))))
	print("Flat normal max channel difference: ", max_difference)
	if max_difference > 0.01:
		push_error("Flat normal changed lighting under full rotation")
		quit(1)
		return
	print("GPU_PROBE_DIR=", OS.get_user_data_dir())
	quit()
