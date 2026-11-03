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
	if demo.get_node("Surface").mesh is BoxMesh:
		push_error("Demo surface is still the flat box")
		quit(1)
		return
	var material := demo.get_node("Surface").material_override as ShaderMaterial
	assert(material != null and material.get_shader_parameter("albedo_map") != null)
	var uniforms := material.shader.get_shader_uniform_list()
	var names: Array[String] = []
	for uniform in uniforms:
		names.append(uniform.name)
	for required in ["rotation_strength", "blend_contrast", "roughness_map", "use_roughness_map", "paper_blend", "paper_falloff", "normal_blend_contrast", "variation_seed", "coherent_blend", "coherent_filter"]:
		if not names.has(required):
			push_error("Missing material control: " + required)
			quit(1)
			return
	assert(material.get_shader_parameter("detile_enabled") == true)
	var first_texture: Variant = material.get_shader_parameter("albedo_map")
	demo.set_texture_set(1)
	assert(material.get_shader_parameter("albedo_map") != first_texture)
	assert(material.get_shader_parameter("roughness_map") != null)
	demo.set_texture_set(2)
	assert(material.get_shader_parameter("albedo_map") != first_texture)
	assert(material.get_shader_parameter("normal_map") != null)
	demo.set_texture_set(8)
	assert(material.get_shader_parameter("albedo_map") != null)
	assert(material.get_shader_parameter("normal_map") != null)
	assert(material.get_shader_parameter("roughness_map") != null)
	demo.set_texture_set(0)
	demo.set_detile(false)
	assert(material.get_shader_parameter("detile_enabled") == false)
	demo.set_detile(true)
	assert(material.get_shader_parameter("detile_enabled") == true)
	print("PASS: scene loads, sample texture is bound, and toggle changes shader mode")
	quit(0)
