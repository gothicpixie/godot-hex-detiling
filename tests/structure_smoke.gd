extends SceneTree
func _initialize() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	var material:ShaderMaterial=demo.get_node("Surface").material_override
	assert(material.get_shader_parameter("structure_enabled")==false)
	assert(demo.structure_toggle.disabled)
	for index in [3,4,7]:
		demo.set_texture_set(index)
		assert(not demo.structure_toggle.disabled)
		demo.set_structure(true)
		assert(material.get_shader_parameter("structure_enabled")==true)
		assert(not demo.rotation_slider.editable)
		assert(demo.structure_toggle.button_pressed)
		var preset:Vector3=demo.STRUCTURE_PRESETS[index]
		assert(material.get_shader_parameter("structure_period")==Vector2(preset.x,preset.y))
		assert(material.get_shader_parameter("structure_stagger")==preset.z)
		var next_index := 4 if index==3 else 7 if index==4 else 3
		demo.set_texture_set(next_index)
		assert(material.get_shader_parameter("structure_enabled")==true)
		assert(not demo.rotation_slider.editable)
		demo.set_structure(false)
		assert(material.get_shader_parameter("structure_enabled")==false)
		assert(demo.rotation_slider.editable)
	demo.set_structure(true)
	demo.set_texture_set(0)
	assert(material.get_shader_parameter("structure_enabled")==false)
	assert(not demo.structure_toggle.button_pressed)
	assert(demo.structure_toggle.disabled)
	assert(demo.rotation_slider.editable)
	demo.set_structure(true)
	assert(material.get_shader_parameter("structure_enabled")==false)
	print("PASS: structure opt-in, supported presets, rotation control, unsupported reset")
	quit()
