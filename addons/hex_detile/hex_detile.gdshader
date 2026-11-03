// Hex detiling adapted from the author's chain-racing material; see README.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool detile_enabled = true;
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

// Stochastic triangular lattice. Offset-only sampling intentionally keeps
// every PBR map in a material set aligned; normals need no counter-rotation.
vec2 detile_hash2(vec2 p) {
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

vec3 detile_sample_color(sampler2D tex, vec2 st, vec2 dx, vec2 dy) {
	float w1, w2, w3;
	ivec2 v1, v2, v3;
	detile_triangle_grid(st, w1, w2, w3, v1, v2, v3);
	vec3 W = pow(vec3(w1, w2, w3), vec3(detile_blend_power));
	W /= max(W.x + W.y + W.z, 1e-12);
	vec2 o1 = detile_hash2(vec2(v1));
	vec2 o2 = detile_hash2(vec2(v2));
	vec2 o3 = detile_hash2(vec2(v3));
	vec3 c1 = textureGrad(tex, st + o1, dx, dy).rgb;
	vec3 c2 = textureGrad(tex, st + o2, dx, dy).rgb;
	vec3 c3 = textureGrad(tex, st + o3, dx, dy).rgb;
	if (detile_detrend > 0.0) {
		vec3 target = textureLod(tex, vec2(0.5), 16.0).rgb;
		ivec2 map_size = textureSize(tex, 0);
		float map_dimension = float(max(map_size.x, map_size.y));
		float effective_lod = clamp(detile_detrend_lod + log2(max(map_dimension / 512.0, 0.0001)), 0.0, log2(map_dimension));
		vec3 l1 = textureLod(tex, st + o1, effective_lod).rgb;
		vec3 l2 = textureLod(tex, st + o2, effective_lod).rgb;
		vec3 l3 = textureLod(tex, st + o3, effective_lod).rgb;
		c1 *= mix(vec3(1.0), target / max(l1, vec3(0.04)), detile_detrend);
		c2 *= mix(vec3(1.0), target / max(l2, vec3(0.04)), detile_detrend);
		c3 *= mix(vec3(1.0), target / max(l3, vec3(0.04)), detile_detrend);
	}
	return c1 * W.x + c2 * W.y + c3 * W.z;
}

vec3 detile_sample_data(sampler2D tex, vec2 st, vec2 dx, vec2 dy) {
	float w1, w2, w3;
	ivec2 v1, v2, v3;
	detile_triangle_grid(st, w1, w2, w3, v1, v2, v3);
	vec3 W = pow(vec3(w1, w2, w3), vec3(detile_blend_power));
	W /= max(W.x + W.y + W.z, 1e-12);
	vec2 o1 = detile_hash2(vec2(v1));
	vec2 o2 = detile_hash2(vec2(v2));
	vec2 o3 = detile_hash2(vec2(v3));
	return textureGrad(tex, st + o1, dx, dy).rgb * W.x
		+ textureGrad(tex, st + o2, dx, dy).rgb * W.y
		+ textureGrad(tex, st + o3, dx, dy).rgb * W.z;
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
	vec3 nx = detile_sample_data(tex, uv_x, dx_x, dy_x) * 2.0 - 1.0;
	vec3 ny = detile_sample_data(tex, uv_y, dx_y, dy_y) * 2.0 - 1.0;
	vec3 nz = detile_sample_data(tex, uv_z, dx_z, dy_z) * 2.0 - 1.0;
	vec3 perturb_x = vec3(0.0, -nx.y, sx * nx.x);
	vec3 perturb_y = vec3(-sy * ny.x, 0.0, ny.y);
	vec3 perturb_z = vec3(sz * nz.x, nz.y, 0.0);
	return perturb_x * weights.x + perturb_y * weights.y + perturb_z * weights.z;
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


void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 geometric_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 vec3 n = normalize(geometric_world_normal);
 vec3 weights = pow(abs(n), vec3(4.0));
 weights /= max(weights.x + weights.y + weights.z, 0.0001);
 vec3 perturb;
 if (detile_enabled) {
  ALBEDO = detile_triplanar_color(albedo_map, world_position, texture_scale_m, n, weights);
  perturb = detile_triplanar_normal_perturb(normal_map, world_position, texture_scale_m, n, weights);
 } else {
  ALBEDO = triplanar_sample(albedo_map, world_position, texture_scale_m, n, weights).rgb;
  perturb = triplanar_normal_perturb(normal_map, world_position, texture_scale_m, n, weights);
 }
 perturb *= normal_strength;
 perturb -= n * dot(n, perturb);
 NORMAL = normalize((VIEW_MATRIX * vec4(normalize(n + perturb), 0.0)).xyz);
 ROUGHNESS = roughness;
}
