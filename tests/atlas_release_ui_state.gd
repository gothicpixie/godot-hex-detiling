extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate();root.add_child(demo);await process_frame
	if demo.get("texture_selector")==null:
		print("FAIL: source selector state is not exposed/synchronized (expected RED)");quit(1);return
	for index in [3,17,18,0,3]:
		demo.set_texture_set(index)
		assert(demo.texture_selector.selected==demo.current_texture)
	print("PASS: programmatic source changes keep visible menu synchronized");quit()
