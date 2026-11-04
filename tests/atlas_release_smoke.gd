extends SceneTree
func _initialize()->void:
	var code:=FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader")
	if not "uniform int brick_individual_tiles_per_axis = 4" in code:
		print("FAIL: atlas dimension compatibility-default uniform missing (expected RED)")
		quit(1)
		return
	print("PASS: atlas dimension defaults to accepted4x layout")
	quit()
