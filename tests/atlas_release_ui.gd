extends SceneTree
const OUT="res://docs/brick_atlas_release/"
var failures:=0
var demo:Node
var records:Array=[]
func _initialize()->void:call_deferred("run")
func draw()->void:
	for frame in 2:
		await process_frame
		RenderingServer.force_draw(false)
func controls(node:Node,result:Array)->void:
	if node is Control and node.focus_mode!=Control.FOCUS_NONE and node.is_visible_in_tree() and not (node is BaseButton and node.disabled):result.append(node)
	for child in node.get_children():controls(child,result)
func run()->void:
	demo=(load("res://demo.tscn") as PackedScene).instantiate();root.add_child(demo)
	await draw()
	if demo.get("mesh_selector")==null or not demo.has_method("set_mesh") or demo.get("controls_scroll")==null:
		print("FAIL: interactive mesh selector/scroll accessibility missing");quit(1);return
	demo.set_texture_set(3);assert(demo.texture_selector.selected==demo.current_texture)
	demo.set_structure(true);demo.brick_individual_toggle.button_pressed=true;demo.set_mesh(1)
	for window_size in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=window_size;demo.controls_scroll.scroll_vertical=0
		await draw()
		var viewport_rect:=Rect2(Vector2.ZERO,Vector2(root.size));var panel:Rect2=demo.ui_panel.get_global_rect();var scroll:Rect2=demo.controls_scroll.get_global_rect()
		var interactive:Array=[];controls(demo.controls_scroll,interactive);var inaccessible:Array=[]
		for control in interactive:
			control.grab_focus();await draw()
			if not scroll.grow(2).has_point(control.get_global_rect().get_center()):inaccessible.append(str(control.get_path()))
		var fits:=viewport_rect.encloses(panel)
		if not fits or not inaccessible.is_empty():failures+=1
		records.append({"test":"controls_accessibility","size":[root.size.x,root.size.y],"panel_rect":str(panel),"panel_fits":fits,"focusable_controls":interactive.size(),"inaccessible":inaccessible,"scroll_max":demo.controls_scroll.get_v_scroll_bar().max_value,"scroll_page":demo.controls_scroll.get_v_scroll_bar().page})
		demo.controls_scroll.scroll_vertical=0;await draw();root.get_texture().get_image().save_png(OUT+"ui-"+str(root.size.x)+"-top.png")
		demo.controls_scroll.scroll_vertical=100000;await draw();root.get_texture().get_image().save_png(OUT+"ui-"+str(root.size.x)+"-bottom.png")
	root.size=Vector2i(1280,720);demo.controls_scroll.scroll_vertical=0
	for index in 4:
		demo.mesh_selector.select(index);demo.mesh_selector.item_selected.emit(index);await draw()
		if demo.current_mesh!=index:failures+=1
		var surface:MeshInstance3D=demo.get_node("Surface");var camera:Camera3D=demo.get_node("Camera3D");var box:=surface.mesh.get_aabb();var minimum:=Vector2(INF,INF);var maximum:=Vector2(-INF,-INF);var behind:=false
		for corner in 8:
			var p:=surface.to_global(box.get_endpoint(corner));behind=behind or camera.is_position_behind(p);var q:=camera.unproject_position(p);minimum=minimum.min(q);maximum=maximum.max(q)
		records.append({"test":"mesh_switch","index":index,"mesh_type":surface.mesh.get_class(),"camera":str(camera.position),"bbox_screen_min":str(minimum),"bbox_screen_max":str(maximum),"some_bbox_points_behind_camera":behind})
		if index>0 and (behind or not Rect2(minimum,maximum-minimum).intersects(Rect2(Vector2.ZERO,Vector2(root.size)))):failures+=1
		root.get_texture().get_image().save_png(OUT+"ui-mesh-"+str(index)+".png")
	FileAccess.open(OUT+"ui-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"records":records,"failures":failures},"\t"))
	print("UI failures=",failures);quit(1 if failures else 0)
