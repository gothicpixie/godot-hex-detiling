extends SceneTree

func _initialize() -> void:
	var scene := load("res://demo.tscn") as PackedScene
	if scene == null:
		push_error("Demo scene could not be loaded")
		quit(1)
		return
	var demo := scene.instantiate()
	root.add_child(demo)
	await process_frame
	var material := demo.get_node("Surface").material_override as ShaderMaterial
	assert(material != null and material.get_shader_parameter("albedo_map") != null)
	assert(material.get_shader_parameter("detile_enabled") == true)
	demo.set_detile(false)
	assert(material.get_shader_parameter("detile_enabled") == false)
	demo.set_detile(true)
	assert(material.get_shader_parameter("detile_enabled") == true)
	print("PASS: scene loads, sample texture is bound, and toggle changes shader mode")
	quit(0)
