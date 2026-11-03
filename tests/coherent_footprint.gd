# Isolate procedural blend-mask aliasing from texture filtering and lighting.
# Compare point samples and footprint relaxation with an 8x8 supersampled
# reference of the unrelaxed field. Analysis: tests/coherent_media.py.
extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var prefix := FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void vertex()")[0]
	prefix = prefix.replace('shader_type spatial;', 'shader_type canvas_item;')
	prefix = prefix.replace('render_mode diffuse_burley, specular_schlick_ggx;', 'render_mode unshaded;')
	prefix = prefix.replace('#include "coherent_blend.gdshaderinc"', '#include "res://addons/hex_detile/coherent_blend.gdshaderinc"')
	var shader := Shader.new()
	shader.code = prefix + '''
uniform float field_scale = 20.0;
uniform vec2 field_offset = vec2(0.0);
void fragment() {
 vec2 st = UV * field_scale + field_offset;
 float w1, w2, w3; ivec2 v1, v2, v3;
 detile_triangle_grid(st, w1, w2, w3, v1, v2, v3);
 vec3 values = vec3(detile_hash2(vec2(v1)).x, detile_hash2(vec2(v2)).x, detile_hash2(vec2(v3)).x);
 vec3 W = coherent_weights(vec3(w1,w2,w3), values, vec3(0.0), dFdx(st), dFdy(st));
 COLOR = vec4(vec3(dot(values,W)), 1.0);
}
'''
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rect := ColorRect.new()
	viewport.add_child(rect)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("normal_strength", 0.0)
	mat.set_shader_parameter("blend_contrast", 0.65)
	rect.material = mat
	for scale_value in [2, 8, 20]:
		mat.set_shader_parameter("field_scale", float(scale_value))
		for mode in ["point", "relaxed", "reference"]:
			var size := 1024 if mode == "reference" else 128
			viewport.size = Vector2i(size, size)
			rect.size = Vector2(size, size)
			mat.set_shader_parameter("coherent_filter", mode == "relaxed")
			for frame in 3:
				await process_frame
				await RenderingServer.frame_post_draw
			var name := "res://docs/coherent/footprint-%d-%s.png" % [scale_value, mode]
			var error := viewport.get_texture().get_image().save_png(name)
			if error != OK:
				push_error("Failed to save " + name)
				quit(1)
				return
	print("Captured isolated footprint probe at three scales")
	quit()
