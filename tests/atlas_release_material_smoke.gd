extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var script:GDScript=load("res://demo.gd")
	var constants:=script.get_script_constant_map()
	var presets:Dictionary=constants.get("BRICK_PRESETS",{})
	if not presets.has(17) or not presets.has(18):
		print("FAIL: prepared Red Brick/Large Red Bricks descriptors missing (expected RED)")
		quit(1)
		return
	for index in [17,18]:
		var preset:Dictionary=presets[index]
		for field in ["mask","packed_albedo","atlas","tiles_per_axis"]:
			assert(preset.has(field))
		assert(constants.TEXTURE_SETS.size()>index and constants.TEXTURE_NAMES.size()>index)
		for path in [preset.mask,preset.packed_albedo,preset.atlas]:assert(FileAccess.file_exists(path))
		if "--expect-supported" in OS.get_cmdline_user_args():assert(preset.get("supported",false))
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate();root.add_child(demo);await process_frame
	demo.set_texture_set(3);demo.set_structure(true);demo.brick_individual_toggle.button_pressed=true
	assert(demo.get_node("Surface").material_override.get_shader_parameter("brick_individual_enabled"))
	for index in [17,18,0]:
		demo.set_texture_set(index)
		assert(not demo.get_node("Surface").material_override.get_shader_parameter("brick_individual_enabled"))
		if index in [17,18]:assert(demo.brick_individual_toggle.disabled and not demo.brick_individual_toggle.tooltip_text.is_empty())
	demo.set_texture_set(3);demo.set_structure(true);assert(demo.get_node("Surface").material_override.get_shader_parameter("brick_individual_enabled"))
	demo.brick_individual_toggle.button_pressed=false;demo.brick_macro_toggle.button_pressed=true
	for index in [17,18]:
		demo.set_texture_set(index);assert(not demo.get_node("Surface").material_override.get_shader_parameter("brick_macro_enabled"))
		assert(not demo.get_node("Surface").material_override.get_shader_parameter("albedo_map").resource_path.ends_with("brick_4_albedo_guard_normalized.png"))
	print("PASS: appended source paths, unsupported gating, palette restoration and Brick4-only macro")
	quit()
