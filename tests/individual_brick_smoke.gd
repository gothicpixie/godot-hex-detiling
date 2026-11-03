extends SceneTree
func _initialize()->void: call_deferred("run")
func run()->void:
	var code:=FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader")
	if not "uniform bool brick_individual_enabled = false" in code:
		print("FAIL: default-off individual brick interface missing (expected RED)")
		quit(1)
		return
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	var mat:ShaderMaterial=demo.get_node("Surface").material_override
	assert(not mat.get_shader_parameter("brick_individual_enabled"))
	assert(demo.brick_individual_toggle.disabled)
	demo.set_texture_set(3)
	demo.set_structure(true)
	assert(not mat.get_shader_parameter("brick_individual_enabled"))
	demo.brick_individual_toggle.button_pressed=true
	assert(mat.get_shader_parameter("brick_individual_enabled"))
	assert(not mat.get_shader_parameter("brick_macro_enabled"))
	assert(mat.get_shader_parameter("albedo_map").resource_path.ends_with("brick_4_albedo_guard.png"))
	assert(mat.get_shader_parameter("brick_individual_map").resource_path.ends_with("brick_4_individual_atlas_seed0.png"))
	assert(mat.get_shader_parameter("brick_individual_map").resource_path.ends_with("brick_4_individual_atlas_seed0.png"))
	demo.set_detile(false)
	assert(not mat.get_shader_parameter("brick_individual_enabled"))
	demo.set_detile(true)
	assert(mat.get_shader_parameter("brick_individual_enabled"))
	demo.set_texture_set(0)
	assert(not mat.get_shader_parameter("brick_individual_enabled"))
	print("PASS: default-off individual brick eligibility and original guide binding")
	quit()
