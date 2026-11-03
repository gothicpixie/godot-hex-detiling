extends Node3D

var detiled := true
var toggle: Button

func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("191c21")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d5d4ce")
	environment.ambient_light_energy = 0.65
	$WorldEnvironment.environment = environment
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "HEX DETILING  /  GODOT"
	heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "Same material, light and camera in both modes."
	box.add_child(subtitle)
	toggle = Button.new()
	toggle.pressed.connect(func(): set_detile(not detiled))
	box.add_child(toggle)
	var help := Label.new()
	help.text = "Space: toggle  ·  1/2/3: viewpoints  ·  Drag: rotate  ·  Wheel: zoom"
	box.add_child(help)
	set_detile(true)

func set_detile(enabled: bool) -> void:
	detiled = enabled
	($Surface.material_override as ShaderMaterial).set_shader_parameter("detile_enabled", enabled)
	if toggle:
		toggle.text = "DETILING ON  —  click to compare" if enabled else "PERIODIC TILING  —  click to compare"

func set_view(index: int) -> void:
	var positions := [Vector3(0, 0, 14), Vector3(6, 1, 14), Vector3(4, 7, 14)]
	if index < 0 or index >= positions.size():
		return
	$Surface.rotation = Vector3.ZERO
	$Camera3D.position = positions[index]
	$Camera3D.look_at(Vector3.ZERO, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		set_detile(not detiled)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_3:
		set_view(event.keycode - KEY_1)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		$Surface.rotate_y(event.relative.x * 0.005)
		$Surface.rotate_x(event.relative.y * 0.005)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$Camera3D.position = $Camera3D.position.normalized() * maxf(8.0, $Camera3D.position.length() - 0.7)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$Camera3D.position = $Camera3D.position.normalized() * minf(20.0, $Camera3D.position.length() + 0.7)
