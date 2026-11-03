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
	quit()
