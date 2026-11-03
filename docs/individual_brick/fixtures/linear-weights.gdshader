// Hex detiling adapted from the author's chain-racing material; see README.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_roughness_map = false;
uniform float rotation_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float blend_contrast : hint_range(0.01, 0.99, 0.01) = 0.5;
uniform bool paper_blend = false;
// Coherent mode takes precedence over paper_blend; legacy defaults are unchanged.
uniform bool coherent_blend = false;
uniform bool coherent_filter = true;
uniform float paper_falloff : hint_range(0.0, 0.99, 0.01) = 0.6;
uniform float normal_blend_contrast : hint_range(0.01, 0.99, 0.01) = 0.5;
uniform float variation_seed : hint_range(0.0, 999.0, 1.0) = 0.0;
uniform bool detile_enabled = true;
// Optional source-UV lattice constraint; independent of blend mode.
uniform bool structure_enabled = false;
// Optional source-aligned mask: black protects the reference, white permits donors.
// Guarding uses coherent weights and requires both structure and detiling.
uniform bool structure_guard_enabled = false;
// Opt-in packed linear mask in albedo alpha; RGB remains source color.
uniform bool structure_guard_in_albedo_alpha = false;
// Local experiment: a filtered, world-anchored scalar color field; off by default.
uniform bool brick_macro_enabled = false;
// Local finite-atlas experiment: aligned original source PBR, independently recolored bricks.
uniform bool brick_individual_enabled = false;
// Direct atlas remains a test ablation; aligned integer shifts keep geometry phase.
uniform bool brick_individual_stochastic = true;
uniform sampler2D brick_individual_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float brick_macro_strength : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform sampler2D structure_guard_map : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 structure_period = vec2(1.0);
uniform float structure_stagger : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float texture_scale_m : hint_range(0.1, 10.0, 0.1) = 1.5;
uniform float normal_strength : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.9;
uniform float detile_blend_power : hint_range(1.0, 16.0, 0.1) = 7.0;
uniform float detile_detrend : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float detile_detrend_lod : hint_range(0.0, 12.0, 0.1) = 6.0;
varying vec3 world_position;
varying vec3 geometric_world_normal;
float axis_sign(float value) {
	return value < 0.0 ? -1.0 : 1.0;
}

// Stochastic triangular lattice. Cell transforms are shared across PBR maps.
vec2 detile_hash2(vec2 p) {
	p += variation_seed * vec2(19.19, 13.17);
	mat2 m = mat2(vec2(127.1, 269.5), vec2(311.7, 183.3));
	return fract(sin(m * p) * 43758.5453);
}

void detile_triangle_grid(vec2 st, out float w1, out float w2, out float w3,
		out ivec2 v1, out ivec2 v2, out ivec2 v3) {
	st *= 2.0 * sqrt(3.0);
	mat2 to_skew = mat2(vec2(1.0, 0.0), vec2(-0.57735027, 1.15470054));
	vec2 sk = to_skew * st;
	ivec2 base = ivec2(floor(sk));
	vec2 f = fract(sk);
	float z = 1.0 - f.x - f.y;
	if (z > 0.0) {
		w1 = z; w2 = f.y; w3 = f.x;
		v1 = base; v2 = base + ivec2(0, 1); v3 = base + ivec2(1, 0);
	} else {
		w1 = -z; w2 = 1.0 - f.y; w3 = 1.0 - f.x;
		v1 = base + ivec2(1, 1); v2 = base + ivec2(1, 0); v3 = base + ivec2(0, 1);
	}
}

// Per-cell transforms are shared by all texture maps. Rotating around the
// lattice vertex keeps the transform stable throughout a cell.
mat2 detile_rotation(ivec2 vertex) {
	if (structure_enabled) {
		return mat2(vec2(1.0, 0.0), vec2(0.0, 1.0));
	}
	float angle = (detile_hash2(vec2(vertex) + vec2(19.7, 53.1)).x * 2.0 - 1.0) * PI * rotation_strength;
	float c = cos(angle); float s = sin(angle);
	return mat2(vec2(c, s), vec2(-s, c));
}
vec2 detile_position(vec2 st, ivec2 vertex, mat2 rotation) {
	if (structure_enabled) {
		// Bounded integer shifts preserve a supplied template lattice. A zero
		// period component locks that coordinate; full-repeat steps add no variety.
		vec2 steps = floor(detile_hash2(vec2(vertex)) * 9.0) - vec2(4.0);
		return st + vec2((steps.x + steps.y * structure_stagger) * structure_period.x,
			steps.y * structure_period.y);
	}
	mat2 inverse_skew = mat2(vec2(1.0, 0.0), vec2(0.5, 1.0 / 1.15470054));
	vec2 center = inverse_skew * vec2(vertex) / (2.0 * sqrt(3.0));
	return rotation * (st - center) + center + detile_hash2(vec2(vertex));
}
vec3 detile_base_weights(float w1, float w2, float w3) {
	vec3 w = pow(vec3(w1, w2, w3), vec3(detile_blend_power));
	return w / max(w.x + w.y + w.z, 0.000001);
}
vec3 detile_gain(vec3 w, float contrast) {
	w /= max(w.x + w.y + w.z, 0.000001);
	float k = log(1.0 - contrast) / log(0.5);
	vec3 side = 2.0 * step(vec3(0.5), w);
	vec3 m = 2.0 * (1.0 - side);
	w = 0.5 * side + 0.25 * m * pow(max(vec3(0.0), side + w * m), vec3(k));
	return w / max(w.x + w.y + w.z, 0.000001);
}
vec3 paper_color_weights(vec3 base, vec3 c1, vec3 c2, vec3 c3) {
	vec3 luminance = vec3(0.299, 0.587, 0.114);
	vec3 brightness = max(vec3(0.0), vec3(dot(c1, luminance), dot(c2, luminance), dot(c3, luminance)));
	return detile_gain(base * mix(vec3(1.0), brightness, paper_falloff), blend_contrast);
}
// Reconstruct Z from XY so the method also works with two-channel normal imports.
// Clamp grazing slopes to avoid numerical blowups from compressed normal maps.
vec2 paper_normal_slope(vec3 encoded, mat2 rotation) {
	vec2 xy = encoded.xy * 2.0 - 1.0;
	float z = sqrt(max(1.0 - dot(xy, xy), 0.0025));
	return transpose(rotation) * (xy / z);
}

vec3 detile_sample_color(sampler2D tex, vec2 st, vec2 dx, vec2 dy) {
	float w1, w2, w3;
	ivec2 v1, v2, v3;
	detile_triangle_grid(st, w1, w2, w3, v1, v2, v3);
	vec3 base = detile_base_weights(w1, w2, w3);
	vec3 W = detile_gain(base, blend_contrast);
	mat2 r1 = detile_rotation(v1); mat2 r2 = detile_rotation(v2); mat2 r3 = detile_rotation(v3);
	vec2 p1 = detile_position(st, v1, r1); vec2 p2 = detile_position(st, v2, r2); vec2 p3 = detile_position(st, v3, r3);
	vec3 c1 = textureGrad(tex, p1, r1 * dx, r1 * dy).rgb;
	vec3 c2 = textureGrad(tex, p2, r2 * dx, r2 * dy).rgb;
	vec3 c3 = textureGrad(tex, p3, r3 * dx, r3 * dy).rgb;
	if (paper_blend) {
		W = paper_color_weights(base, c1, c2, c3);
	}
	if (detile_detrend > 0.0) {
		vec3 target = textureLod(tex, vec2(0.5), 16.0).rgb;
		ivec2 map_size = textureSize(tex, 0);
		float map_dimension = float(max(map_size.x, map_size.y));
		float effective_lod = clamp(detile_detrend_lod + log2(max(map_dimension / 512.0, 0.0001)), 0.0, log2(map_dimension));
		vec3 l1 = textureLod(tex, p1, effective_lod).rgb;
		vec3 l2 = textureLod(tex, p2, effective_lod).rgb;
		vec3 l3 = textureLod(tex, p3, effective_lod).rgb;
		c1 *= mix(vec3(1.0), target / max(l1, vec3(0.04)), detile_detrend);
		c2 *= mix(vec3(1.0), target / max(l2, vec3(0.04)), detile_detrend);
		c3 *= mix(vec3(1.0), target / max(l3, vec3(0.04)), detile_detrend);
	}
	return c1 * W.x + c2 * W.y + c3 * W.z;
}

vec3 detile_sample_data(sampler2D tex, vec2 st, vec2 dx, vec2 dy, bool is_normal) {
	float w1, w2, w3;
	ivec2 v1, v2, v3;
	detile_triangle_grid(st, w1, w2, w3, v1, v2, v3);
	vec3 base = detile_base_weights(w1, w2, w3);
	vec3 W = detile_gain(base, blend_contrast);
	mat2 r1 = detile_rotation(v1); mat2 r2 = detile_rotation(v2); mat2 r3 = detile_rotation(v3);
	vec2 p1 = detile_position(st, v1, r1); vec2 p2 = detile_position(st, v2, r2); vec2 p3 = detile_position(st, v3, r3);
	vec3 c1 = textureGrad(tex, p1, r1 * dx, r1 * dy).rgb;
	vec3 c2 = textureGrad(tex, p2, r2 * dx, r2 * dy).rgb;
	vec3 c3 = textureGrad(tex, p3, r3 * dx, r3 * dy).rgb;
	if (paper_blend && is_normal) {
		vec2 d1 = paper_normal_slope(c1, r1);
		vec2 d2 = paper_normal_slope(c2, r2);
		vec2 d3 = paper_normal_slope(c3, r3);
		vec3 slope2 = vec3(dot(d1, d1), dot(d2, d2), dot(d3, d3));
		vec3 slope_weight = sqrt(slope2 / (vec3(1.0) + slope2));
		W = detile_gain(base * mix(vec3(1.0), slope_weight, paper_falloff), normal_blend_contrast);
		vec2 blended_slope = d1 * W.x + d2 * W.y + d3 * W.z;
		vec3 normal = normalize(vec3(blended_slope, 1.0));
		return normal * 0.5 + 0.5;
	}
	if (paper_blend && !is_normal) {
		W = paper_color_weights(base, c1, c2, c3);
	}
	if (is_normal) {
		c1.xy = transpose(r1) * (c1.xy * 2.0 - 1.0) * 0.5 + 0.5;
		c2.xy = transpose(r2) * (c2.xy * 2.0 - 1.0) * 0.5 + 0.5;
		c3.xy = transpose(r3) * (c3.xy * 2.0 - 1.0) * 0.5 + 0.5;
	}
	return c1 * W.x + c2 * W.y + c3 * W.z;
}

vec3 detile_triplanar_color(sampler2D tex, vec3 p, float scale_m, vec3 n, vec3 weights) {
	float sx = axis_sign(n.x);
	float sy = axis_sign(n.y);
	float sz = axis_sign(n.z);
	vec2 uv_x = vec2(sx * p.z, -p.y) / scale_m;
	vec2 uv_y = vec2(-sy * p.x, p.z) / scale_m;
	vec2 uv_z = vec2(sz * p.x, p.y) / scale_m;
	vec2 dx_x = dFdx(uv_x); vec2 dy_x = dFdy(uv_x);
	vec2 dx_y = dFdx(uv_y); vec2 dy_y = dFdy(uv_y);
	vec2 dx_z = dFdx(uv_z); vec2 dy_z = dFdy(uv_z);
	return detile_sample_color(tex, uv_x, dx_x, dy_x) * weights.x
		+ detile_sample_color(tex, uv_y, dx_y, dy_y) * weights.y
		+ detile_sample_color(tex, uv_z, dx_z, dy_z) * weights.z;
}

vec3 detile_triplanar_normal_perturb(
		sampler2D tex, vec3 p, float scale_m, vec3 n, vec3 weights) {
	float sx = axis_sign(n.x);
	float sy = axis_sign(n.y);
	float sz = axis_sign(n.z);
	vec2 uv_x = vec2(sx * p.z, -p.y) / scale_m;
	vec2 uv_y = vec2(-sy * p.x, p.z) / scale_m;
	vec2 uv_z = vec2(sz * p.x, p.y) / scale_m;
	vec2 dx_x = dFdx(uv_x); vec2 dy_x = dFdy(uv_x);
	vec2 dx_y = dFdx(uv_y); vec2 dy_y = dFdy(uv_y);
	vec2 dx_z = dFdx(uv_z); vec2 dy_z = dFdy(uv_z);
	vec3 nx = detile_sample_data(tex, uv_x, dx_x, dy_x, true) * 2.0 - 1.0;
	vec3 ny = detile_sample_data(tex, uv_y, dx_y, dy_y, true) * 2.0 - 1.0;
	vec3 nz = detile_sample_data(tex, uv_z, dx_z, dy_z, true) * 2.0 - 1.0;
	vec3 perturb_x = vec3(0.0, -nx.y, sx * nx.x);
	vec3 perturb_y = vec3(-sy * ny.x, 0.0, ny.y);
	vec3 perturb_z = vec3(sz * nz.x, nz.y, 0.0);
	return perturb_x * weights.x + perturb_y * weights.y + perturb_z * weights.z;
}

vec3 detile_triplanar_data(sampler2D tex, vec3 p, float scale_m, vec3 n, vec3 weights) {
	vec2 x = vec2(axis_sign(n.x) * p.z, -p.y) / scale_m;
	vec2 y = vec2(-axis_sign(n.y) * p.x, p.z) / scale_m;
	vec2 z = vec2(axis_sign(n.z) * p.x, p.y) / scale_m;
	return detile_sample_data(tex, x, dFdx(x), dFdy(x), false) * weights.x
		+ detile_sample_data(tex, y, dFdx(y), dFdy(y), false) * weights.y
		+ detile_sample_data(tex, z, dFdx(z), dFdy(z), false) * weights.z;
}

vec4 triplanar_sample(sampler2D tex, vec3 p, float scale_m, vec3 n, vec3 weights) {
	float sx = axis_sign(n.x);
	float sy = axis_sign(n.y);
	float sz = axis_sign(n.z);
	vec2 uv_x = vec2(sx * p.z, -p.y) / scale_m;
	vec2 uv_y = vec2(-sy * p.x, p.z) / scale_m;
	vec2 uv_z = vec2(sz * p.x, p.y) / scale_m;
	return texture(tex, uv_x) * weights.x
		+ texture(tex, uv_y) * weights.y
		+ texture(tex, uv_z) * weights.z;
}

vec3 triplanar_normal_perturb(
	sampler2D tex, vec3 p, float scale_m, vec3 n, vec3 weights
) {
	float sx = axis_sign(n.x);
	float sy = axis_sign(n.y);
	float sz = axis_sign(n.z);
	vec2 uv_x = vec2(sx * p.z, -p.y) / scale_m;
	vec2 uv_y = vec2(-sy * p.x, p.z) / scale_m;
	vec2 uv_z = vec2(sz * p.x, p.y) / scale_m;
	vec3 nx = texture(tex, uv_x).xyz * 2.0 - 1.0;
	vec3 ny = texture(tex, uv_y).xyz * 2.0 - 1.0;
	vec3 nz = texture(tex, uv_z).xyz * 2.0 - 1.0;
	// Only the sampled tangent components are added to the geometric normal.
	// A flat normal map therefore contributes exactly zero at any strength.
	vec3 perturb_x = vec3(0.0, -nx.y, sx * nx.x);
	vec3 perturb_y = vec3(-sy * ny.x, 0.0, ny.y);
	vec3 perturb_z = vec3(sz * nz.x, nz.y, 0.0);
	return perturb_x * weights.x + perturb_y * weights.y + perturb_z * weights.z;
}


#include "coherent_blend.gdshaderinc"

// Analytic box-pixel integral of a sine wave. Gradients are world-space, so
// the field is shared by all triplanar projections and has no camera/time phase.
float brick_macro_sinc(float half_width) {
	return abs(half_width) < 0.0001 ? 1.0 : sin(half_width) / half_width;
}
float brick_macro_wave(vec3 p, vec3 dx, vec3 dy, vec3 frequency, float phase) {
	float angle = TAU * dot(p, frequency) + phase;
	float half_dx = PI * dot(dx, frequency);
	float half_dy = PI * dot(dy, frequency);
	return sin(angle) * brick_macro_sinc(half_dx) * brick_macro_sinc(half_dy);
}
float brick_macro_gain(vec3 p, vec3 dx, vec3 dy) {
	p /= texture_scale_m; dx /= texture_scale_m; dy /= texture_scale_m;
	float seed = variation_seed;
	float field = brick_macro_wave(p, dx, dy, vec3(0.133, 0.071, 0.109), seed * 0.71)
		+ brick_macro_wave(p, dx, dy, vec3(-0.079, 0.127, 0.043), seed * 1.37 + 1.9)
		+ brick_macro_wave(p, dx, dy, vec3(0.053, -0.061, 0.151), seed * 2.11 + 4.1);
	// Each integrated wave is bounded by one; gain remains within 2^(+/-strength).
	return exp2(brick_macro_strength * field / 3.0);
}

// Full-resolution atlas spans four source repeats. Every integer SOURCE-tile
// offset keeps mortar and fine-detail geometry at the same phase. Only palettes vary.
float brick_individual_detail(vec2 dx, vec2 dy) {
	// Triangle grid uses st/2; start fading only as individual bricks become unresolved.
	float footprint = max(length(dx), length(dy)) * sqrt(3.0);
	return 1.0 - smoothstep(0.125, 0.5, footprint);
}
vec3 brick_individual_color(vec2 uv, vec2 dx, vec2 dy, vec3 atlas_mean) {
	if (!brick_individual_stochastic) {
		return textureGrad(brick_individual_map, uv / 4.0, dx / 4.0, dy / 4.0).rgb;
	}
	float detail = brick_individual_detail(dx, dy);
	if (detail == 0.0) {
		return atlas_mean;
	}
	float w1, w2, w3;
	ivec2 v1, v2, v3;
	detile_triangle_grid(uv / 2.0, w1, w2, w3, v1, v2, v3);
	vec3 W = vec3(w1, w2, w3);
	W /= max(W.x + W.y + W.z, 1e-20);
	vec2 o1 = floor(detile_hash2(vec2(v1) + vec2(83.71, 27.13)) * 4.0);
	vec2 o2 = floor(detile_hash2(vec2(v2) + vec2(83.71, 27.13)) * 4.0);
	vec2 o3 = floor(detile_hash2(vec2(v3) + vec2(83.71, 27.13)) * 4.0);
	vec4 c1 = textureGrad(brick_individual_map, (uv + o1) / 4.0, dx / 4.0, dy / 4.0);
	vec4 c2 = textureGrad(brick_individual_map, (uv + o2) / 4.0, dx / 4.0, dy / 4.0);
	vec4 c3 = textureGrad(brick_individual_map, (uv + o3) / 4.0, dx / 4.0, dy / 4.0);
	vec3 color = c1.rgb * W.x + c2.rgb * W.y + c3.rgb * W.z;
	// All palette variants preserve native protected RGB. Select one to avoid
	// rounding their identical colors; never let this bypass the coarse fade.
	if (c1.a == 0.0) {
		color = c1.rgb;
	}
	if (detail < 1.0) {
		color = mix(atlas_mean, color, detail);
	}
	return color;
}
void brick_individual_sample(vec2 uv, vec2 dx, vec2 dy, vec3 atlas_mean,
		out vec3 color, out vec3 normal, out float material_roughness) {
	color = brick_individual_color(uv, dx, dy, atlas_mean);
	vec2 slope = paper_normal_slope(textureGrad(normal_map, uv, dx, dy).rgb,
		mat2(vec2(1.0, 0.0), vec2(0.0, 1.0)));
	normal = normalize(vec3(slope, 1.0));
	material_roughness = roughness;
	if (use_roughness_map) {
		material_roughness = textureGrad(roughness_map, uv, dx, dy).r;
	}
}
void brick_individual_triplanar_material(vec3 p, vec3 n, vec3 weights,
		out vec3 color, out vec3 perturb, out float material_roughness) {
	float sx = axis_sign(n.x); float sy = axis_sign(n.y); float sz = axis_sign(n.z);
	vec2 x = vec2(sx * p.z, -p.y) / texture_scale_m;
	vec2 y = vec2(-sy * p.x, p.z) / texture_scale_m;
	vec2 z = vec2(sz * p.x, p.y) / texture_scale_m;
	vec2 dx_x = dFdx(x); vec2 dy_x = dFdy(x);
	vec2 dx_y = dFdx(y); vec2 dy_y = dFdy(y);
	vec2 dx_z = dFdx(z); vec2 dy_z = dFdy(z);
	// One shared last-mip mean read, only when any projection needs the coarse fade.
	vec3 atlas_mean = vec3(0.0);
	if (brick_individual_stochastic && (brick_individual_detail(dx_x, dy_x) < 1.0
			|| brick_individual_detail(dx_y, dy_y) < 1.0 || brick_individual_detail(dx_z, dy_z) < 1.0)) {
		atlas_mean = textureLod(brick_individual_map, vec2(0.5), 16.0).rgb;
	}
	vec3 cx, cy, cz, nx, ny, nz;
	float rx, ry, rz;
	brick_individual_sample(x, dx_x, dy_x, atlas_mean, cx, nx, rx);
	brick_individual_sample(y, dx_y, dy_y, atlas_mean, cy, ny, ry);
	brick_individual_sample(z, dx_z, dy_z, atlas_mean, cz, nz, rz);
	color = cx * weights.x + cy * weights.y + cz * weights.z;
	perturb = vec3(0.0, -nx.y, sx * nx.x) * weights.x
		+ vec3(-sy * ny.x, 0.0, ny.y) * weights.y
		+ vec3(sz * nz.x, nz.y, 0.0) * weights.z;
	material_roughness = dot(vec3(rx, ry, rz), weights);
}

void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 geometric_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 bool individual_active = brick_individual_enabled && detile_enabled && structure_enabled && structure_guard_enabled;
 // Compute derivatives before any data-dependent return inside material sampling.
 vec3 macro_dx = vec3(0.0); vec3 macro_dy = vec3(0.0);
 if (brick_macro_enabled && !individual_active && brick_macro_strength > 0.0) {
  macro_dx = dFdx(world_position); macro_dy = dFdy(world_position);
 }
 vec3 n = normalize(geometric_world_normal);
 vec3 weights = pow(abs(n), vec3(4.0));
 weights /= max(weights.x + weights.y + weights.z, 0.0001);
 vec3 perturb;
 float coherent_roughness = roughness;
 if (individual_active) {
  brick_individual_triplanar_material(world_position, n, weights, ALBEDO, perturb, coherent_roughness);
 } else if (detile_enabled && (coherent_blend || (structure_enabled && structure_guard_enabled))) {
  coherent_triplanar_material(world_position, texture_scale_m, n, weights, ALBEDO, perturb, coherent_roughness);
 } else if (detile_enabled) {
  ALBEDO = detile_triplanar_color(albedo_map, world_position, texture_scale_m, n, weights);
  perturb = detile_triplanar_normal_perturb(normal_map, world_position, texture_scale_m, n, weights);
 } else {
  ALBEDO = triplanar_sample(albedo_map, world_position, texture_scale_m, n, weights).rgb;
  perturb = triplanar_normal_perturb(normal_map, world_position, texture_scale_m, n, weights);
 }
 if (brick_macro_enabled && !individual_active && brick_macro_strength > 0.0) {
  ALBEDO *= brick_macro_gain(world_position, macro_dx, macro_dy);
 }
 perturb *= normal_strength;
 perturb -= n * dot(n, perturb);
 NORMAL = normalize((VIEW_MATRIX * vec4(normalize(n + perturb), 0.0)).xyz);
 ROUGHNESS = coherent_roughness;
 if (use_roughness_map && !(detile_enabled && (coherent_blend || (structure_enabled && structure_guard_enabled)))) {
  ROUGHNESS = detile_enabled ? detile_triplanar_data(roughness_map, world_position, texture_scale_m, n, weights).r : triplanar_sample(roughness_map, world_position, texture_scale_m, n, weights).r;
 }
}
