// Project-specific synthesis: one content-guided material mixture, relaxed
// with pixel footprint. This is not an analytic filter or a novel-paper claim.
vec3 coherent_weights(vec3 bary, vec3 brightness, vec3 relief, vec2 dx, vec2 dy) {
	float footprint = max(length(dx), length(dy)) * (2.0 * sqrt(3.0));
	float detail = coherent_filter ? 1.0 - smoothstep(0.125, 0.5, footprint) : 1.0;
	vec3 base = pow(max(bary, vec3(0.0)), vec3(mix(1.0, detile_blend_power, detail)));
	// At power 16, three equal raw weights total about 7e-8. Normalize
	// before the gain helper so its epsilon cannot collapse that mixture.
	base /= max(base.x + base.y + base.z, 1e-20);
	float influence = paper_falloff * detail;
	vec3 color_vote = mix(vec3(1.0), clamp(brightness, vec3(0.0), vec3(1.0)), influence);
	vec3 normal_vote = mix(vec3(1.0), clamp(relief, vec3(0.0), vec3(1.0)), influence);
	// Geometric mean combines bounded positive signals without counting the
	// barycentric prior twice. An unused normal map cannot steer the blend.
	vec3 guide = pow(color_vote * pow(normal_vote, vec3(normal_strength)), vec3(1.0 / (1.0 + normal_strength)));
	return detile_gain(base * guide, mix(0.5, blend_contrast, detail));
}

void coherent_sample_material(vec2 st, vec2 dx, vec2 dy,
		out vec3 color, out vec3 normal, out float material_roughness) {
	float w1, w2, w3;
	ivec2 v1, v2, v3;
	detile_triangle_grid(st, w1, w2, w3, v1, v2, v3);
	mat2 r1 = detile_rotation(v1); mat2 r2 = detile_rotation(v2); mat2 r3 = detile_rotation(v3);
	vec2 p1 = detile_position(st, v1, r1); vec2 p2 = detile_position(st, v2, r2); vec2 p3 = detile_position(st, v3, r3);
	vec2 dx1 = r1 * dx; vec2 dy1 = r1 * dy;
	vec2 dx2 = r2 * dx; vec2 dy2 = r2 * dy;
	vec2 dx3 = r3 * dx; vec2 dy3 = r3 * dy;
	vec3 c1 = textureGrad(albedo_map, p1, dx1, dy1).rgb;
	vec3 c2 = textureGrad(albedo_map, p2, dx2, dy2).rgb;
	vec3 c3 = textureGrad(albedo_map, p3, dx3, dy3).rgb;
	vec2 d1 = paper_normal_slope(textureGrad(normal_map, p1, dx1, dy1).rgb, r1);
	vec2 d2 = paper_normal_slope(textureGrad(normal_map, p2, dx2, dy2).rgb, r2);
	vec2 d3 = paper_normal_slope(textureGrad(normal_map, p3, dx3, dy3).rgb, r3);
	vec3 slope2 = vec3(dot(d1, d1), dot(d2, d2), dot(d3, d3));
	vec3 relief = sqrt(slope2 / (vec3(1.0) + slope2));
	vec3 luminance = vec3(0.299, 0.587, 0.114);
	vec3 brightness = vec3(dot(c1, luminance), dot(c2, luminance), dot(c3, luminance));
	vec3 W = coherent_weights(vec3(w1, w2, w3), brightness, relief, dx, dy);
	if (detile_detrend > 0.0) {
		vec3 target = textureLod(albedo_map, vec2(0.5), 16.0).rgb;
		ivec2 map_size = textureSize(albedo_map, 0);
		float map_dimension = float(max(map_size.x, map_size.y));
		float lod = clamp(detile_detrend_lod + log2(max(map_dimension / 512.0, 0.0001)), 0.0, log2(map_dimension));
		c1 *= mix(vec3(1.0), target / max(textureLod(albedo_map, p1, lod).rgb, vec3(0.04)), detile_detrend);
		c2 *= mix(vec3(1.0), target / max(textureLod(albedo_map, p2, lod).rgb, vec3(0.04)), detile_detrend);
		c3 *= mix(vec3(1.0), target / max(textureLod(albedo_map, p3, lod).rgb, vec3(0.04)), detile_detrend);
	}
	color = c1 * W.x + c2 * W.y + c3 * W.z;
	normal = normalize(vec3(d1 * W.x + d2 * W.y + d3 * W.z, 1.0));
	material_roughness = roughness;
	if (use_roughness_map) {
		vec3 values = vec3(textureGrad(roughness_map, p1, dx1, dy1).r,
			textureGrad(roughness_map, p2, dx2, dy2).r, textureGrad(roughness_map, p3, dx3, dy3).r);
		material_roughness = dot(values, W);
	}
}

void coherent_triplanar_material(vec3 p, float scale_m, vec3 n, vec3 weights,
		out vec3 color, out vec3 perturb, out float material_roughness) {
	float sx = axis_sign(n.x); float sy = axis_sign(n.y); float sz = axis_sign(n.z);
	vec2 x = vec2(sx * p.z, -p.y) / scale_m;
	vec2 y = vec2(-sy * p.x, p.z) / scale_m;
	vec2 z = vec2(sz * p.x, p.y) / scale_m;
	vec3 cx, cy, cz, nx, ny, nz;
	float rx, ry, rz;
	coherent_sample_material(x, dFdx(x), dFdy(x), cx, nx, rx);
	coherent_sample_material(y, dFdx(y), dFdy(y), cy, ny, ry);
	coherent_sample_material(z, dFdx(z), dFdy(z), cz, nz, rz);
	color = cx * weights.x + cy * weights.y + cz * weights.z;
	perturb = vec3(0.0, -nx.y, sx * nx.x) * weights.x
		+ vec3(-sy * ny.x, 0.0, ny.y) * weights.y
		+ vec3(sz * nz.x, nz.y, 0.0) * weights.z;
	material_roughness = dot(vec3(rx, ry, rz), weights);
}
