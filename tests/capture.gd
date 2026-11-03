extends SceneTree
func _initialize() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	root.get_texture().get_image().save_png("res://docs/detiled.png")
	demo.set_detile(false)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/periodic.png")
	demo.set_detile(true)
	demo.set_view(1)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/oblique.png")
	demo.set_detile(false)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/oblique-periodic.png")
	demo.set_detile(true)
	demo.set_view(2)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/elevated.png")
	demo.set_detile(false)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/elevated-periodic.png")
	for child in demo.get_children():
		if child is CanvasLayer:
			child.visible = false
	demo.set_view(0)
	demo.set_texture_set(1)
	demo.set_detile(false)
	var mat: ShaderMaterial = demo.get_node("Surface").material_override
	mat.set_shader_parameter("rotation_strength", 0.75)
	mat.set_shader_parameter("blend_contrast", 0.65)
	mat.set_shader_parameter("use_roughness_map", true)
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/sandstone-periodic.png")
	demo.set_detile(true)
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://docs/sandstone-detiled.png")
	quit()
