@tool
extends EditorPlugin

const SHADER := preload("res://addons/hex_detile/hex_detile.gdshader")
var dock: VBoxContainer
var info: Label
var create_button: Button

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Hex Detiling"
	var heading := Label.new()
	heading.text = "Hex Detiling"
	dock.add_child(heading)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(info)
	create_button = Button.new()
	create_button.text = "Create material on selected mesh"
	create_button.pressed.connect(_create_material)
	dock.add_child(create_button)
	var instructions := Label.new()
	instructions.text = "Select the new material in the Inspector to assign textures and adjust sampling. Existing material overrides are never replaced."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(instructions)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	EditorInterface.get_selection().selection_changed.connect(_update_selection)
	_update_selection()

func _exit_tree() -> void:
	EditorInterface.get_selection().selection_changed.disconnect(_update_selection)
	remove_control_from_docks(dock)
	dock.queue_free()

func _update_selection() -> void:
	var nodes := EditorInterface.get_selection().get_selected_nodes()
	var valid := nodes.size() == 1 and nodes[0] is MeshInstance3D
	if valid and nodes[0].material_override != null:
		info.text = "Selected mesh already has a material override."
		create_button.disabled = true
	elif valid:
		info.text = "Selected: " + nodes[0].name
		create_button.disabled = false
	else:
		info.text = "Select one MeshInstance3D to begin."
		create_button.disabled = true

func _create_material() -> void:
	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() != 1 or not nodes[0] is MeshInstance3D or nodes[0].material_override != null:
		return
	var material := ShaderMaterial.new()
	material.shader = SHADER
	var undo := get_undo_redo()
	undo.create_action("Create hex detiling material")
	undo.add_do_property(nodes[0], "material_override", material)
	undo.add_undo_property(nodes[0], "material_override", null)
	undo.commit_action()
	EditorInterface.inspect_object(material)
	_update_selection()
