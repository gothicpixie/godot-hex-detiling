extends SceneTree
func _initialize() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	var material: ShaderMaterial = demo.get_node("Surface").material_override
	material.set_shader_parameter("rotation_strength", 1.0)
	material.set_shader_parameter("paper_blend", true)
	material.set_shader_parameter("normal_strength", 0.0)
	await create_timer(1.0).timeout
	var no_normal := root.get_texture().get_image()
	material.set_shader_parameter("normal_strength", 1.0)
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	var with_normal := root.get_texture().get_image()
	var nonflat_difference := max_difference(no_normal, with_normal)
	print("Textured normal max channel difference: ", nonflat_difference)
	if nonflat_difference < 0.03:
		push_error("Non-flat normal map did not affect the paper mode image")
		quit(1)
		return
	var flat := Image.create(8, 8, false, Image.FORMAT_RGBAF)
	flat.fill(Color(0.5, 0.5, 1.0, 1.0))
	material.set_shader_parameter("normal_map", ImageTexture.create_from_image(flat))
	for paper in [false, true]:
		material.set_shader_parameter("paper_blend", paper)
		material.set_shader_parameter("normal_strength", 0.0)
		await process_frame
		await process_frame
		await create_timer(0.3).timeout
		var baseline := root.get_texture().get_image()
		material.set_shader_parameter("normal_strength", 1.0)
		await process_frame
		await process_frame
		await create_timer(0.3).timeout
		var rotated := root.get_texture().get_image()
		var difference := max_difference(baseline, rotated)
		print("Flat normal max channel difference, paper=", paper, ": ", difference)
		if difference > 0.01:
			push_error("Flat normal changed lighting under full rotation")
			quit(1)
			return
	demo.set_texture_set(8)
	material.set_shader_parameter("texture_scale_m", 2.5)
	material.set_shader_parameter("blend_contrast", 0.65)
	material.set_shader_parameter("use_roughness_map", true)
	material.set_shader_parameter("normal_strength", 0.5)
	material.set_shader_parameter("rotation_strength", 0.65)
	material.set_shader_parameter("paper_blend", false)
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	var shared_image := root.get_texture().get_image()
	material.set_shader_parameter("paper_blend", true)
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	var paper_image := root.get_texture().get_image()
	var mode_difference := mean_difference(shared_image, paper_image)
	print("Shared vs paper mean RGB difference: ", mode_difference)
	if mode_difference < 0.0001:
		push_error("Paper toggle produced no measurable difference on cobblestone")
		quit(1)
		return
	print("PASS: flat normals remain flat, textured normals affect lighting, and paper mode changes output")
	quit()

func max_difference(a: Image, b: Image) -> float:
	var max_delta := 0.0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var first := a.get_pixel(x, y)
			var second := b.get_pixel(x, y)
			max_delta = maxf(max_delta, maxf(absf(first.r - second.r), maxf(absf(first.g - second.g), absf(first.b - second.b))))
	return max_delta

func mean_difference(a: Image, b: Image) -> float:
	var sum := 0.0
	var count := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var first := a.get_pixel(x, y)
			var second := b.get_pixel(x, y)
			sum += (absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b)) / 3.0
			count += 1
	return sum / float(count)
