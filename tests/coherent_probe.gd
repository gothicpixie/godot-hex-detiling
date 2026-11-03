# GPU checks against the production shader helpers (no CPU reimplementation).
extends SceneTree

var failures := 0
var prefix: String
var viewport: SubViewport
var rect: ColorRect
var material: ShaderMaterial

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	prefix = FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void vertex()")[0]
	if not "coherent_blend" in prefix:
		push_error("FAIL: coherent material mode is missing")
		quit(1)
		return
	prefix = prefix.replace('#include "coherent_blend.gdshaderinc"', '#include "res://addons/hex_detile/coherent_blend.gdshaderinc"')
	prefix = prefix.replace("shader_type spatial;", "shader_type canvas_item;")
	prefix = prefix.replace("render_mode diffuse_burley, specular_schlick_ggx;", "render_mode unshaded;")
	viewport = SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	rect = ColorRect.new()
	rect.size = Vector2(128, 128)
	viewport.add_child(rect)
	material = ShaderMaterial.new()
	rect.material = material
	var near := "vec3(0.2, 0.3, 0.5), vec3(0.05, 0.9, 0.3), vec3(0.8, 0.1, 0.5), vec2(0.001, 0.0), vec2(0.0, 0.001)"
	var far := "vec3(0.2, 0.3, 0.5), vec3(0.05, 0.9, 0.3), vec3(0.8, 0.1, 0.5), vec2(0.3, 0.0), vec2(0.0, 0.3)"
	var near_pixel := await sample("COLOR = vec4(coherent_weights(" + near + "), 1.0);")
	check(absf(near_pixel.r + near_pixel.g + near_pixel.b - 1.0) < 0.015, "weights sum to one")
	var far_pixel := await sample("COLOR = vec4(coherent_weights(" + far + "), 1.0);")
	check(color_distance(far_pixel, Color(0.2, 0.3, 0.5)) < 0.012, "far weights relax to barycentric")
	check(color_distance(near_pixel, far_pixel) > 0.1, "footprint changes sharp near weights")
	var edge := await sample("COLOR = vec4(coherent_weights(vec3(0.0, 0.4, 0.6), vec3(1.0, 0.1, 0.8), vec3(1.0, 0.7, 0.2), vec2(0.001), vec2(0.001)), 1.0);")
	check(edge.r < 0.004, "zero barycentric support stays zero")
	var permuted := await sample("COLOR = vec4(coherent_weights(vec3(0.5, 0.2, 0.3), vec3(0.3, 0.05, 0.9), vec3(0.5, 0.8, 0.1), vec2(0.001, 0.0), vec2(0.0, 0.001)), 1.0);")
	check(color_distance(permuted, Color(near_pixel.b, near_pixel.r, near_pixel.g)) < 0.012, "candidate permutation preserves weights")
	material.set_shader_parameter("normal_strength", 0.0)
	var no_normal_a := await sample("COLOR = vec4(coherent_weights(" + near + "), 1.0);")
	var no_normal_b := await sample("COLOR = vec4(coherent_weights(" + near.replace("vec3(0.8, 0.1, 0.5)", "vec3(0.0, 1.0, 0.0)") + "), 1.0);")
	check(color_distance(no_normal_a, no_normal_b) < 0.004, "disabled normal does not guide weights")
	material.set_shader_parameter("normal_strength", 0.5)
	material.set_shader_parameter("detile_blend_power", 16.0)
	material.set_shader_parameter("blend_contrast", 0.99)
	var extreme := await sample("COLOR = vec4(coherent_weights(vec3(1.0/3.0), vec3(0.2), vec3(0.2), vec2(0.001), vec2(0.001)), 1.0);")
	check(color_distance(extreme, Color(1.0/3.0, 1.0/3.0, 1.0/3.0)) < 0.012, "maximum contrast preserves normalized equal mixture")
	material.set_shader_parameter("detile_blend_power", 7.0)
	material.set_shader_parameter("blend_contrast", 0.5)
	# Albedo + roughness = 1 in these linear float fixtures. Independent
	# content weights break that relationship; shared weights must preserve it.
	var texture_image := Image.create(32, 32, true, Image.FORMAT_RGBAF)
	for y in 32:
		for x in 32:
			var value := 0.05 if (x / 8 + y / 8) % 2 == 0 else 0.95
			texture_image.set_pixel(x, y, Color(value, value, value, 1.0))
	texture_image.generate_mipmaps()
	var tex := ImageTexture.create_from_image(texture_image)
	var flat := Image.create(4, 4, false, Image.FORMAT_RGBAF)
	flat.fill(Color(0.5, 0.5, 1.0, 1.0))
	material.set_shader_parameter("albedo_map", tex)
	var inverse_image := texture_image.duplicate() as Image
	for y in 32:
		for x in 32:
			var value := 1.0 - texture_image.get_pixel(x, y).r
			inverse_image.set_pixel(x, y, Color(value, value, value, 1.0))
	inverse_image.generate_mipmaps()
	material.set_shader_parameter("roughness_map", ImageTexture.create_from_image(inverse_image))
	material.set_shader_parameter("normal_map", ImageTexture.create_from_image(flat))
	material.set_shader_parameter("use_roughness_map", true)
	material.set_shader_parameter("rotation_strength", 0.65)
	var result := await render("vec3 c; vec3 n; float r; vec2 p = UV * 3.0; coherent_sample_material(p, dFdx(p), dFdy(p), c, n, r); COLOR = vec4(abs(c.r+r-1.0), abs(n.x)+abs(n.y), 0.0, 1.0);")
	var max_error := 0.0
	var flat_error := 0.0
	for y in 128:
		for x in 128:
			var pixel := result.get_pixel(x, y)
			max_error = maxf(max_error, pixel.r)
			flat_error = maxf(flat_error, pixel.g)
	check(max_error < 0.008, "correlated color and roughness stay aligned; max=" + str(max_error))
	check(flat_error < 0.004, "flat normals remain flat; max=" + str(flat_error))
	material.set_shader_parameter("paper_blend", true)
	var independent := await render("vec2 p = UV * 3.0; vec2 dx = dFdx(p); vec2 dy = dFdy(p); float c = detile_sample_color(albedo_map, p, dx, dy).r; float r = detile_sample_data(roughness_map, p, dx, dy, false).r; COLOR = vec4(abs(c+r-1.0), 0.0, 0.0, 1.0);")
	var independent_error := 0.0
	for y in 128:
		for x in 128:
			independent_error = maxf(independent_error, independent.get_pixel(x, y).r)
	check(independent_error > 0.03, "fixture detects independent paper weights; max=" + str(independent_error))
	# Nearest-sampled two-state fixture: each texel has slope (albedo.r, 0).
	# A common +90-degree UV rotation must undo to (0, -albedo.r).
	# Shared linear blending therefore preserves n.xy/n.z == (0, -color.r),
	# regardless of the guidance formula. No CPU copy of that formula is used.
	var production_prefix := prefix
	prefix = prefix.replace('#include "res://addons/hex_detile/coherent_blend.gdshaderinc"', FileAccess.get_file_as_string("res://addons/hex_detile/coherent_blend.gdshaderinc"))
	prefix = prefix.replace("filter_linear_mipmap_anisotropic", "filter_nearest")
	var rotation_start := prefix.find("mat2 detile_rotation(")
	var rotation_end := prefix.find("\n}", rotation_start) + 2
	prefix = prefix.substr(0, rotation_start) + "mat2 detile_rotation(ivec2 vertex) { return mat2(vec2(0.0, 1.0), vec2(-1.0, 0.0)); }" + prefix.substr(rotation_end)
	var slopes := Image.create(32, 32, false, Image.FORMAT_RGBAF)
	for y in 32:
		for x in 32:
			var slope := texture_image.get_pixel(x, y).r
			var encoded_x := 0.5 + 0.5 * slope / sqrt(1.0 + slope * slope)
			slopes.set_pixel(x, y, Color(encoded_x, 0.5, 1.0, 1.0))
	material.set_shader_parameter("normal_map", ImageTexture.create_from_image(slopes))
	material.set_shader_parameter("coherent_filter", false)
	var slope_body := "vec3 c; vec3 n; float r; vec2 p = UV * 3.0; coherent_sample_material(p, dFdx(p), dFdy(p), c, n, r); COLOR = vec4(min(abs(n.x/n.z), 1.0), min(abs(n.y/n.z+c.r), 1.0), 0.0, 1.0);"
	var coherent_slope := max_channel(await render(slope_body), 1)
	check(coherent_slope < 0.008, "nonflat normal shares color weights and inverse rotation; max=" + str(coherent_slope))
	check(max_channel(await render(slope_body), 0) < 0.004, "quarter-turn inverse rotation leaves zero X slope")
	var fixture_prefix := prefix
	prefix = prefix.replace("d1 * W.x + d2 * W.y + d3 * W.z", "(d1 + d2 + d3) / 3.0")
	var mutated_weights := max_channel(await render(slope_body), 1)
	check(mutated_weights > 0.03, "nonflat fixture rejects independent normal weights; max=" + str(mutated_weights))
	prefix = fixture_prefix.replace("transpose(rotation) * (xy / z)", "rotation * (xy / z)")
	var mutated_rotation := max_channel(await render(slope_body), 1)
	check(mutated_rotation > 0.1, "nonflat fixture rejects forward normal rotation; max=" + str(mutated_rotation))
	prefix = production_prefix
	material.set_shader_parameter("coherent_filter", true)
	material.set_shader_parameter("use_roughness_map", false)
	material.set_shader_parameter("roughness", 0.37)
	var constant := await sample("vec3 c; vec3 n; float r; coherent_sample_material(UV, dFdx(UV), dFdy(UV), c, n, r); COLOR = vec4(vec3(r), 1.0);")
	check(absf(constant.r - 0.37) < 0.008, "disabled roughness map uses constant")
	# Fixed footprint, increasing from just below to just above the relaxation
	# threshold must be continuous (no distance switch/pop).
	var below := await sample("COLOR = vec4(coherent_weights(vec3(0.2, 0.3, 0.5), vec3(0.05, 0.9, 0.3), vec3(0.8, 0.1, 0.5), vec2(0.03608, 0.0), vec2(0.0)), 1.0);")
	var above := await sample("COLOR = vec4(coherent_weights(vec3(0.2, 0.3, 0.5), vec3(0.05, 0.9, 0.3), vec3(0.8, 0.1, 0.5), vec2(0.03609, 0.0), vec2(0.0)), 1.0);")
	check(color_distance(below, above) < 0.008, "footprint transition is continuous")
	print("Coherent GPU checks: ", failures, " failures")
	quit(1 if failures else 0)

func render(body: String) -> Image:
	var shader := Shader.new()
	shader.code = prefix + "\nvoid fragment() { " + body + " }\n"
	material.shader = shader
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()

func sample(body: String) -> Color:
	var result := await render(body)
	return result.get_pixel(64, 64)

func check(passed: bool, message: String) -> void:
	print("PASS: " if passed else "FAIL: ", message)
	if not passed:
		failures += 1

func color_distance(a: Color, b: Color) -> float:
	return absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b)

func max_channel(result: Image, channel: int) -> float:
	var largest := 0.0
	for y in result.get_height():
		for x in result.get_width():
			largest = maxf(largest, result.get_pixel(x, y)[channel])
	return largest
