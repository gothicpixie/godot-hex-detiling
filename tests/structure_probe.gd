# Compile and exercise production shader helpers on the GPU. Analytic fixtures
# define layout independently of the production shift/hash implementation.
extends SceneTree
var failures := 0
var prefix: String
var viewport: SubViewport
var material: ShaderMaterial

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	prefix = FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void vertex()")[0]
	if not "uniform bool structure_enabled" in prefix:
		check(false, "production structure-aware mode exists")
		quit(1)
		return
	prefix = prefix.replace('#include "coherent_blend.gdshaderinc"', '#include "res://addons/hex_detile/coherent_blend.gdshaderinc"').replace("shader_type spatial;", "shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;", "render_mode unshaded;")
	viewport = SubViewport.new()
	viewport.size = Vector2i(192, 192)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rect := ColorRect.new()
	rect.size = Vector2(192,192)
	viewport.add_child(rect)
	material = ShaderMaterial.new()
	rect.material = material
	material.set_shader_parameter("structure_enabled", true)
	material.set_shader_parameter("rotation_strength", 1.0)
	material.set_shader_parameter("structure_period", Vector2(0.25, 0.125))
	material.set_shader_parameter("structure_stagger", 0.5)
	# Brick running-bond phase: y repeats every row; x subtracts half a brick
	# per continuous row coordinate. This includes negative world positions.
	var brick := "vec2 p=UV*4.0-vec2(2.17,2.31); ivec2 v=ivec2(floor(UV*29.0))-ivec2(17); mat2 r=detile_rotation(v); vec2 q=detile_position(p,v,r); vec2 a=vec2(p.x/0.25-0.5*p.y/0.125,p.y/0.125); vec2 b=vec2(q.x/0.25-0.5*q.y/0.125,q.y/0.125); COLOR=vec4(abs(sin(a*TAU)-sin(b*TAU)),0.0,1.0);"
	check(max_channel(await render(brick),0)<0.008 and max_channel(await render(brick),1)<0.008, "brick mortar phase preserved with stagger, negative coordinates, full rotation")
	material.set_shader_parameter("structure_stagger", 0.0)
	material.set_shader_parameter("structure_period", Vector2(0.25,0.25))
	var checker := "vec2 p=UV*4.0-vec2(2.17,2.31); ivec2 v=ivec2(floor(UV*29.0))-ivec2(17); vec2 q=detile_position(p,v,detile_rotation(v)); float a=sin(p.x*TAU/0.25)*sin(p.y*TAU/0.25); float b=sin(q.x*TAU/0.25)*sin(q.y*TAU/0.25); COLOR=vec4(abs(a-b),0.0,0.0,1.0);"
	check(max_channel(await render(checker),0)<0.008,"checker parity phase preserved")
	material.set_shader_parameter("structure_enabled",false)
	material.set_shader_parameter("rotation_strength",0.0)
	var unconstrained_phase := mean_channel(await render(checker),0)
	check(unconstrained_phase>0.1,"checker fixture detects offset-only phase damage; mean="+str(unconstrained_phase))
	material.set_shader_parameter("structure_enabled",true)
	material.set_shader_parameter("rotation_strength",1.0)
	material.set_shader_parameter("structure_period",Vector2(0.0,0.125))
	var board := "vec2 p=UV*4.0-vec2(2.17,2.31); ivec2 v=ivec2(floor(UV*29.0))-ivec2(17); vec2 q=detile_position(p,v,detile_rotation(v)); COLOR=vec4(abs(p.x-q.x),abs(sin(p.y*TAU/0.125)-sin(q.y*TAU/0.125)),0.0,1.0);"
	var board_image := await render(board)
	check(max_channel(board_image,0)<0.004 and max_channel(board_image,1)<0.008,"board stripe phase and locked axis preserved")
	var orientation := await render("mat2 r=detile_rotation(ivec2(floor(UV*43.0))-ivec2(23)); vec2 n=paper_normal_slope(vec3(0.7,0.6,1.0),r); vec2 base=paper_normal_slope(vec3(0.7,0.6,1.0),mat2(vec2(1,0),vec2(0,1))); COLOR=vec4(abs(n-base),0,1);")
	check(max_channel(orientation,0)<0.004 and max_channel(orientation,1)<0.004,"nonflat normal orientation untouched at rotation_strength=1")
	# Actual compiled material sampler: repeated row layout in red; per-row
	# microappearance in green. Red must match periodic, green must change.
	var image := Image.create(128,128,false,Image.FORMAT_RGBAF)
	for y in 128:
		for x in 128:
			image.set_pixel(x,y,Color(0.2 if y%16<3 else 0.8, float((x*13+y*7)%113)/112.0,0.4,1.0))
	material.set_shader_parameter("albedo_map",ImageTexture.create_from_image(image))
	material.set_shader_parameter("structure_period",Vector2(0.0,0.125))
	material.set_shader_parameter("coherent_filter",false)
	prefix = prefix.replace("filter_linear_mipmap_anisotropic","filter_nearest")
	var body := "vec2 p=UV*3.0-vec2(1.17,1.31); vec3 c=detile_sample_color(albedo_map,p,dFdx(p),dFdy(p)); vec3 b=textureGrad(albedo_map,p,dFdx(p),dFdy(p)).rgb; COLOR=vec4(abs(c.r-b.r),abs(c.g-b.g),0,1);"
	for paper in [false,true]:
		material.set_shader_parameter("paper_blend",paper)
		var actual := await render(body)
		check(max_channel(actual,0)<0.008,"sampled row layout preserved paper="+str(paper))
		check(mean_channel(actual,1)>0.03,"sampled microappearance varies paper="+str(paper)+" mean="+str(mean_channel(actual,1)))
	# Negative control: an identity shift keeps layout but is not detiling.
	var original_prefix := prefix
	var start := prefix.find("vec2 detile_position(")
	var finish := prefix.find("\n}",start)+2
	prefix=prefix.substr(0,start)+"vec2 detile_position(vec2 st,ivec2 vertex,mat2 rotation){return st;}"+prefix.substr(finish)
	check(mean_channel(await render(body),1)<0.008,"microappearance fixture rejects zero-shift mutation")
	prefix=original_prefix
	var flat := Image.create(4,4,false,Image.FORMAT_RGBAF)
	flat.fill(Color(0.7,0.6,1.0,1.0))
	material.set_shader_parameter("normal_map",ImageTexture.create_from_image(flat))
	material.set_shader_parameter("normal_strength",1.0)
	material.set_shader_parameter("coherent_blend",true)
	var shared := await render("vec2 p=UV*3.0-vec2(1.17,1.31); vec3 c; vec3 n; float rough; coherent_sample_material(p,dFdx(p),dFdy(p),c,n,rough); COLOR=vec4(abs(c.r-textureGrad(albedo_map,p,dFdx(p),dFdy(p)).r),abs(n.x/n.z-0.4/sqrt(0.8)),abs(n.y/n.z-0.2/sqrt(0.8)),1);")
	check(max_channel(shared,0)<0.008,"coherent sampled structure preserved")
	check(max_channel(shared,1)<0.008 and max_channel(shared,2)<0.008,"coherent sampled nonflat normal orientation preserved")
	var inverse := image.duplicate() as Image
	for y in 128:
		for x in 128:
			var value := 1.0-image.get_pixel(x,y).g
			inverse.set_pixel(x,y,Color(value,value,value,1))
	material.set_shader_parameter("roughness_map",ImageTexture.create_from_image(inverse))
	material.set_shader_parameter("use_roughness_map",true)
	var aligned := await render("vec2 p=UV*3.0-vec2(1.17,1.31);vec3 c;vec3 n;float r;coherent_sample_material(p,dFdx(p),dFdy(p),c,n,r);COLOR=vec4(abs(c.g+r-1.0),0,0,1);")
	check(max_channel(aligned,0)<0.008,"structure candidates and weights align color and roughness")
	# Cross exact skew-cell and diagonal support boundaries at tiny epsilon.
	# Smooth interpolation is required here: nearest texture texels legitimately jump.
	var nearest_prefix := prefix
	prefix=prefix.replace("filter_nearest","filter_linear")
	var seam := await render("float t=UV.y*8.0-4.0; vec2 p=vec2(1.0+0.5*t,t/1.15470054)/(2.0*sqrt(3.0)); vec2 e=vec2(0.00001,0); vec3 a=detile_sample_color(albedo_map,p-e,vec2(0.0001,0),vec2(0,0.0001)); vec3 b=detile_sample_color(albedo_map,p+e,vec2(0.0001,0),vec2(0,0.0001)); COLOR=vec4(abs(a-b),1);")
	check(max_channel(seam,0)<0.008 and max_channel(seam,1)<0.008,"no out-of-support color seams across lattice cell edges")
	var diagonal := await render("float t=UV.y*8.0-4.0; vec2 sk=vec2(t,1.0-t); vec2 p=vec2(sk.x+0.5*sk.y,sk.y/1.15470054)/(2.0*sqrt(3.0)); vec2 e=vec2(0.00001,0); vec3 a;vec3 na;float ra;vec3 b;vec3 nb;float rb; coherent_sample_material(p-e,vec2(0.0001,0),vec2(0,0.0001),a,na,ra);coherent_sample_material(p+e,vec2(0.0001,0),vec2(0,0.0001),b,nb,rb);COLOR=vec4(abs(a-b),1);")
	check(max_channel(diagonal,0)<0.008 and max_channel(diagonal,1)<0.008,"no coherent support seams across triangle diagonals")
	prefix=nearest_prefix
	material.set_shader_parameter("structure_period",Vector2(1.0,1.0))
	var degenerate := await render(body)
	check(mean_channel(degenerate,1)<0.008,"full-texture lattice degenerates to periodic; no novelty claimed")
	material.set_shader_parameter("structure_period",Vector2(0.25,0.125))
	var selection := "vec2 p=detile_position(vec2(0),ivec2(floor(UV*17.0))-ivec2(9),mat2(vec2(1,0),vec2(0,1))); COLOR=vec4(fract(p*vec2(0.71,0.63)),0,1);"
	material.set_shader_parameter("variation_seed",0.0)
	var seed_a := await render(selection)
	material.set_shader_parameter("variation_seed",7.0)
	var seed_b := await render(selection)
	material.set_shader_parameter("variation_seed",0.0)
	var seed_reset := await render(selection)
	check(mean_difference(seed_a,seed_b)>0.03,"seed changes lattice selection")
	check(mean_difference(seed_a,seed_reset)<0.001,"seed reset deterministic")
	# Disabled structure ignores all structure settings, retaining legacy path.
	material.set_shader_parameter("structure_enabled",false)
	var off := await render(selection)
	var off_sample := await render(body)
	material.set_shader_parameter("structure_period",Vector2(0.001,10.0))
	material.set_shader_parameter("structure_stagger",0.91)
	check(mean_difference(off,await render(selection))<0.001,"disabled mode ignores period/stagger")
	var current_prefix := prefix
	var old_shader := FileAccess.get_file_as_string("/tmp/hex-structure-baseline.gdshader")
	if not old_shader.is_empty():
		prefix=old_shader.split("void vertex()")[0].replace('#include "coherent_blend.gdshaderinc"', FileAccess.get_file_as_string("/tmp/hex-structure-baseline.gdshaderinc")).replace("shader_type spatial;", "shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;", "render_mode unshaded;").replace("filter_linear_mipmap_anisotropic","filter_nearest")
		check(mean_difference(off,await render(selection))<0.001,"disabled transforms match original shader at 5b86dca")
		check(mean_difference(off_sample,await render(body))<0.001,"disabled sampled image matches original shader at 5b86dca")
		prefix=current_prefix
	else:
		print("SKIP: original-shader regression; run git show 5b86dca:addons/hex_detile/hex_detile.gdshader > /tmp/hex-structure-baseline.gdshader")
	material.set_shader_parameter("structure_enabled",true)
	for period in [Vector2.ZERO,Vector2(0.001,0.001),Vector2(10,10)]:
		material.set_shader_parameter("structure_period",period)
		var extreme := await render("vec2 p=UV*9.0-vec2(4.37); ivec2 v=ivec2(floor(UV*41.0))-ivec2(25); vec2 q=detile_position(p,v,detile_rotation(v)); COLOR=vec4(vec3(float(any(isnan(q)) || any(isinf(q)))),1);")
		check(max_channel(extreme,0)<0.004,"finite transforms at period="+str(period))
	print("Structure GPU checks: ",failures," failures")
	quit(1 if failures else 0)

func render(body: String) -> Image:
	var shader := Shader.new()
	shader.code=prefix+"\nvoid fragment(){"+body+"}\n"
	material.shader=shader
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func check(ok: bool,message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func max_channel(image: Image,channel: int) -> float:
	var result := 0.0
	for y in image.get_height():
		for x in image.get_width(): result=maxf(result,image.get_pixel(x,y)[channel])
	return result
func mean_channel(image: Image,channel: int) -> float:
	var result := 0.0
	for y in image.get_height():
		for x in image.get_width(): result+=image.get_pixel(x,y)[channel]
	return result/float(image.get_width()*image.get_height())
func mean_difference(a: Image,b: Image) -> float:
	var result := 0.0
	for y in a.get_height():
		for x in a.get_width():
			var ca:=a.get_pixel(x,y)
			var cb:=b.get_pixel(x,y)
			result+=absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)
	return result/float(a.get_width()*a.get_height()*3)
