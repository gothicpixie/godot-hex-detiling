extends Node3D

var detiled := true
var toggle: Button
const TEXTURE_SETS := [
	["res://assets/rock_albedo.png", "res://assets/rock_normal.png", "res://assets/rock_roughness.png"],
	["res://assets/sandstone_albedo.png", "res://assets/sandstone_normal.png", "res://assets/sandstone_roughness.png"],
	["res://assets/boulder_albedo.png", "res://assets/boulder_normal.png", "res://assets/boulder_roughness.png"],
]

func _ready() -> void:
	$Surface.mesh = make_terrain()
	set_view(0)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("6a8691")
	sky_material.sky_horizon_color = Color("c8c1a8")
	sky_material.ground_bottom_color = Color("393a35")
	sky_material.ground_horizon_color = Color("918d79")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d5d4ce")
	environment.ambient_light_energy = 0.65
	$WorldEnvironment.environment = environment
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.068, 0.075, 0.91)
	panel_style.set_corner_radius_all(9)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "HEX DETILING"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("efeadf"))
	box.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "One terrain. One texture set. Two sampling modes."
	subtitle.add_theme_color_override("font_color", Color("abb9b7"))
	box.add_child(subtitle)
	toggle = Button.new()
	toggle.pressed.connect(func(): set_detile(not detiled))
	box.add_child(toggle)
	var selector := OptionButton.new()
	selector.add_item("Rocks Ground 04")
	selector.add_item("Sandstone Cracks")
	selector.add_item("Rock Boulder Cracked")
	selector.item_selected.connect(set_texture_set)
	box.add_child(selector)
	var rotation_label := Label.new()
	rotation_label.text = "Tile rotation"
	box.add_child(rotation_label)
	var rotation_slider := HSlider.new()
	rotation_slider.min_value = 0.0
	rotation_slider.max_value = 1.0
	rotation_slider.step = 0.01
	rotation_slider.value = 0.0
	rotation_slider.custom_minimum_size = Vector2(280, 20)
	rotation_slider.value_changed.connect(func(value): ($Surface.material_override as ShaderMaterial).set_shader_parameter("rotation_strength", value))
	box.add_child(rotation_slider)
	var contrast_label := Label.new()
	contrast_label.text = "Blend contrast"
	box.add_child(contrast_label)
	var contrast_slider := HSlider.new()
	contrast_slider.min_value = 0.01
	contrast_slider.max_value = 0.99
	contrast_slider.step = 0.01
	contrast_slider.value = 0.5
	contrast_slider.value_changed.connect(func(value): ($Surface.material_override as ShaderMaterial).set_shader_parameter("blend_contrast", value))
	box.add_child(contrast_slider)
	var roughness_toggle := CheckButton.new()
	roughness_toggle.text = "Use roughness map"
	roughness_toggle.toggled.connect(func(value): ($Surface.material_override as ShaderMaterial).set_shader_parameter("use_roughness_map", value))
	box.add_child(roughness_toggle)
	set_texture_set(0)
	var help := Label.new()
	help.text = "SPACE  compare   ·   1 / 2 / 3  viewpoints   ·   scroll  zoom"
	help.add_theme_color_override("font_color", Color("abb9b7"))
	box.add_child(help)
	set_detile(true)

func set_texture_set(index: int) -> void:
	if index < 0 or index >= TEXTURE_SETS.size():
		return
	var material := $Surface.material_override as ShaderMaterial
	material.set_shader_parameter("albedo_map", load(TEXTURE_SETS[index][0]))
	material.set_shader_parameter("normal_map", load(TEXTURE_SETS[index][1]))
	material.set_shader_parameter("roughness_map", load(TEXTURE_SETS[index][2]))

func set_detile(enabled: bool) -> void:
	detiled = enabled
	($Surface.material_override as ShaderMaterial).set_shader_parameter("detile_enabled", enabled)
	if toggle:
		toggle.text = "DETILING ON     ·     click to compare" if enabled else "REGULAR TILING     ·     click to compare"

func make_terrain() -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = 38
	noise.frequency = 0.16
	noise.fractal_octaves = 4
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var resolution := 160
	var width := 60.0
	for z in resolution:
		for x in resolution:
			var points := [Vector2(x, z), Vector2(x + 1, z), Vector2(x, z + 1), Vector2(x + 1, z), Vector2(x + 1, z + 1), Vector2(x, z + 1)]
			for point in points:
				var px: float = point.x / resolution * width - width / 2.0
				var pz: float = point.y / resolution * width - width / 2.0
				var elevation := noise.get_noise_2d(px, pz) * 1.25
				builder.set_uv(point / resolution)
				builder.add_vertex(Vector3(px, elevation, pz))
	builder.generate_normals()
	return builder.commit()

func set_view(index: int) -> void:
	var positions := [Vector3(0, 7, 9), Vector3(9, 6, 10), Vector3(2, 15, 10)]
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
