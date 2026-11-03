# Independent GPU contract for conservative source-mask guarding.
extends SceneTree
var failures:=0
var prefix:String
var viewport:SubViewport
var material:ShaderMaterial
func _initialize()->void: call_deferred("run")
func run()->void:
	prefix=FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void vertex()")[0]
	if not "uniform bool structure_guard_enabled" in prefix:
		check(false,"production opt-in structure guard exists")
		quit(1)
		return
	prefix=prefix.replace('#include "coherent_blend.gdshaderinc"','#include "res://addons/hex_detile/coherent_blend.gdshaderinc"').replace("shader_type spatial;","shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
	viewport=SubViewport.new()
	viewport.size=Vector2i(192,192)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rect:=ColorRect.new()
	rect.size=Vector2(192,192)
	viewport.add_child(rect)
	material=ShaderMaterial.new()
	rect.material=material
	for key in {"structure_enabled":true,"structure_guard_enabled":true,"detile_enabled":true,"coherent_blend":true,"structure_period":Vector2(0.25,0.125),"structure_stagger":0.5,"normal_strength":1.0,"use_roughness_map":true,"coherent_filter":false,"detile_detrend":0.0}:
		material.set_shader_parameter(key,{"structure_enabled":true,"structure_guard_enabled":true,"detile_enabled":true,"coherent_blend":true,"structure_period":Vector2(0.25,0.125),"structure_stagger":0.5,"normal_strength":1.0,"use_roughness_map":true,"coherent_filter":false,"detile_detrend":0.0}[key])
	var tex:=Image.create(128,128,false,Image.FORMAT_RGBA8)
	var norm:=tex.duplicate() as Image
	var rough:=tex.duplicate() as Image
	for y in 128:
		for x in 128:
			var value:=float((x*13+y*7)%113)/112.0
			tex.set_pixel(x,y,Color(0.2+value*0.6,value,0.5,1))
			norm.set_pixel(x,y,Color(0.45+value*0.15,0.4+value*0.1,1,1))
			rough.set_pixel(x,y,Color(1-value,1-value,1-value,1))
	material.set_shader_parameter("albedo_map",ImageTexture.create_from_image(tex))
	material.set_shader_parameter("normal_map",ImageTexture.create_from_image(norm))
	material.set_shader_parameter("roughness_map",ImageTexture.create_from_image(rough))
	var body:="vec2 p=UV*2.0-vec2(1.17,1.31);vec2 dx=vec2(0.0001,0),dy=vec2(0,0.0001);vec3 c;vec3 n;float r;coherent_sample_material(p,dx,dy,c,n,r);"
	var compare:=body+"vec3 b=textureGrad(albedo_map,p,dx,dy).rgb;vec2 bn=paper_normal_slope(textureGrad(normal_map,p,dx,dy).rgb,mat2(vec2(1,0),vec2(0,1)));float br=textureGrad(roughness_map,p,dx,dy).r;COLOR=vec4(length(c-b),length(n-normalize(vec3(bn,1))),abs(r-br),1);"
	material.set_shader_parameter("structure_guard_map",solid(Color.BLACK))
	var black:=await render(compare)
	check(max_channel(black,0)<0.008 and max_channel(black,1)<0.008 and max_channel(black,2)<0.008,"black reference guard preserves original color, nonflat normal, roughness")
	material.set_shader_parameter("structure_guard_map",solid(Color.WHITE))
	var white:=await render(compare)
	check(mean_channel(white,0)>0.03,"white interior retains meaningful variation; rejects frozen periodic copy")
	var aligned:=await render(body+"COLOR=vec4(abs(c.g+r-1.0),0,0,1);")
	check(max_channel(aligned,0)<0.008,"guard color and roughness share weights")
	# Instrument the compiled production helper's final material assignment to
	# inspect its real post-mask weights without copying the algorithm.
	var weight_prefix:=prefix
	var include:=FileAccess.get_file_as_string("res://addons/hex_detile/coherent_blend.gdshaderinc")
	include=include.replace("color = c0 * anchor_weight + c1 * W.x + c2 * W.y + c3 * W.z;","color = vec3(anchor_weight+W.x+W.y+W.z,0.5+0.25*min(anchor_weight,min(W.x,min(W.y,W.z))),0.5+0.25*max(anchor_weight,max(W.x,max(W.y,W.z))));")
	# Exact source-only return is the one-hot anchor mixture (1,0,0,0).
	# Instrument that real exit too; otherwise mask=0 displays source RGB.
	include=include.replace("color = anchor_sample.rgb;", "color = vec3(1.0,0.5,0.75);")
	prefix=prefix.replace('#include "res://addons/hex_detile/coherent_blend.gdshaderinc"',include)
	for amount in [0.0,0.25,0.5,1.0]:
		material.set_shader_parameter("structure_guard_map",solid(Color(amount,amount,amount,1)))
		var weights:=await render(body+"COLOR=vec4(abs(c.r-1.0),abs(c.g-0.625),max(0.0,c.b-0.75),1);")
		check(max_channel(weights,0)<0.008 and max_channel(weights,1)<0.13 and max_channel(weights,2)<0.008,"compiled guarded weights normalized and bounded mask="+str(amount))
	prefix=weight_prefix
	# Disjoint donor fixture: candidates are forced half a map away. A white
	# reference patch and black donors must leave the reference untouched.
	var original_prefix:=prefix
	var start:=prefix.find("vec2 detile_position(")
	var finish:=prefix.find("\n}",start)+2
	prefix=prefix.substr(0,start)+"vec2 detile_position(vec2 st,ivec2 vertex,mat2 rotation){return st+vec2(0.5,0.0);}"+prefix.substr(finish)
	var half:=Image.create(128,128,false,Image.FORMAT_RGBA8)
	half.fill(Color.BLACK)
	for y in 128:
		for x in 64: half.set_pixel(x,y,Color.WHITE)
	material.set_shader_parameter("structure_guard_map",ImageTexture.create_from_image(half))
	var restricted:=compare.replace("UV*2.0-vec2(1.17,1.31)","UV*vec2(0.2,0.8)+vec2(0.1,0.1)")
	var rejected:=await render(restricted)
	check(max_channel(rejected,0)<0.008 and max_channel(rejected,1)<0.008 and max_channel(rejected,2)<0.008,"black donor rejects foreign material despite white reference")
	prefix=original_prefix
	material.set_shader_parameter("structure_guard_map",solid(Color.WHITE))
	var output:=body+"COLOR=vec4(c,1);"
	material.set_shader_parameter("variation_seed",0.0)
	var seed0:=await render(output)
	material.set_shader_parameter("variation_seed",7.0)
	var seed7:=await render(output)
	material.set_shader_parameter("variation_seed",0.0)
	check(difference(seed0,seed7)>0.01,"seed changes interior variation")
	check(difference(seed0,await render(output))<0.001,"seed reset deterministic")
	# Frozen-prefix baseline includes its original coherent helper, so disabled
	# comparisons cannot accidentally test current code against itself.
	material.set_shader_parameter("structure_guard_enabled",false)
	var disabled:=await render(output)
	var baseline:=FileAccess.get_file_as_string("res://docs/guard_optimization/fixtures/pre-guard-6c9cabf.gdshader")
	var baseline_include:=FileAccess.get_file_as_string("res://docs/guard_optimization/fixtures/pre-guard-6c9cabf.gdshaderinc")
	if not baseline.is_empty() and not baseline_include.is_empty():
		prefix=baseline.split("void vertex()")[0].replace('#include "coherent_blend.gdshaderinc"',baseline_include).replace("shader_type spatial;","shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
		check(difference(disabled,await render(output))<0.001,"guard disabled matches frozen full shader at 6c9cabf")
		prefix=original_prefix
	else: check(false,"baseline shader and include available")
	material.set_shader_parameter("structure_guard_enabled",true)
	material.set_shader_parameter("structure_guard_map",null)
	var missing:=await render(compare)
	check(max_channel(missing,0)<0.008 and max_channel(missing,1)<0.008 and max_channel(missing,2)<0.008,"missing guard map defaults safely to original")
	material.set_shader_parameter("structure_guard_map",solid(Color.WHITE))
	var far:=await render(compare.replace("0.0001","2.0"))
	check(max_channel(far,0)<0.008 and max_channel(far,1)<0.008 and max_channel(far,2)<0.008,"coarse footprint anchors original material")
	# An adversarial smooth ramp with deterministic donors: epsilon offsets
	# detect hard mask gates independently of texture/lattice discontinuities.
	var ramp:=Image.create(128,128,false,Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128: ramp.set_pixel(x,y,Color(float(x)/127.0,float(x)/127.0,float(x)/127.0,1))
	material.set_shader_parameter("structure_guard_map",ImageTexture.create_from_image(ramp))
	var seam:="vec2 p=vec2(0.2+UV.y*0.6,0.31);vec3 a;vec3 na;float ra;vec3 b;vec3 nb;float rb;coherent_sample_material(p-vec2(0.000001,0),vec2(0.0001,0),vec2(0,0.0001),a,na,ra);coherent_sample_material(p+vec2(0.000001,0),vec2(0.0001,0),vec2(0,0.0001),b,nb,rb);COLOR=vec4(length(a-b),length(na-nb),abs(ra-rb),1);"
	var boundary:=await render(seam)
	check(max_channel(boundary,0)<0.008 and max_channel(boundary,1)<0.008 and max_channel(boundary,2)<0.008,"smooth mask boundary has no hard material seam")
	material.set_shader_parameter("structure_period",Vector2(2.0/15.0,1.0/14.0))
	material.set_shader_parameter("structure_stagger",0.5)
	# Direct projected production probe on actual source: this measures the
	# supplied mask's protected pixels, not completeness of mortar labeling.
	for entry in {"albedo_map":"albedo","normal_map":"normal","roughness_map":"roughness"}:
		material.set_shader_parameter(entry,load("res://assets/gallery/brick_4_"+{"albedo_map":"albedo","normal_map":"normal","roughness_map":"roughness"}[entry]+".jpg"))
	material.set_shader_parameter("structure_guard_map",load("res://assets/gallery/brick_4_interior_mask.png"))
	var actual_compare:=compare.replace("UV*2.0-vec2(1.17,1.31)","UV").replace("0.0001","0.0003")
	var actual_error:=await render(actual_compare)
	actual_error.save_png("res://docs/brick_guard/actual-source-error.png")
	var mask_sample:=await render("vec2 p=UV;float m=textureGrad(structure_guard_map,p,vec2(0.0003,0),vec2(0,0.0003)).r;COLOR=vec4(m,m,m,1);")
	var protected:=0
	var interior:=0
	var protected_max:=Vector3.ZERO
	var interior_sum:=0.0
	for y in actual_error.get_height():
		for x in actual_error.get_width():
			var err:=actual_error.get_pixel(x,y)
			if mask_sample.get_pixel(x,y).r<0.001:
				protected+=1
				protected_max=Vector3(maxf(protected_max.x,err.r),maxf(protected_max.y,err.g),maxf(protected_max.z,err.b))
			if mask_sample.get_pixel(x,y).r>0.99:
				interior+=1
				interior_sum+=err.r
	FileAccess.open("res://docs/brick_guard/actual-source-metrics.json",FileAccess.WRITE).store_string(JSON.stringify({"structure_period":[2.0/15.0,1.0/14.0],"structure_stagger":0.5,"seed":0,"dx":[0.0003,0],"dy":[0,0.0003],"mask_footprint_texels":0.3072,"resolution":[192,192],"error_readback":"RGBA8","protected_pixels":protected,"protected_observed_max":[protected_max.x,protected_max.y,protected_max.z],"interior_pixels":interior,"interior_mean_color_l2_delta":interior_sum/maxi(interior,1)},"\t"))
	print("Actual-source diagnostic protected pixels=",protected," max color/normal/roughness=",protected_max," interior pixels=",interior," mean color L2 delta=",interior_sum/maxi(interior,1))
	check(protected>1000 and protected_max.length()<0.008,"actual mask-black pixels preserve all material channels")
	check(interior>1000 and interior_sum/maxi(interior,1)>0.01,"actual mask-white interiors retain measurable variation")
	print("Brick guard GPU checks: ",failures," failures")
	quit(1 if failures else 0)
func solid(color:Color)->ImageTexture:
	var img:=Image.create(8,8,false,Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
func render(body:String)->Image:
	var shader:=Shader.new()
	shader.code=prefix+"\nvoid fragment(){"+body+"}\n"
	material.shader=shader
	for frame in 3:
		await process_frame
		await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func check(ok:bool,message:String)->void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func max_channel(img:Image,ch:int)->float:
	var value:=0.0
	for y in img.get_height():
		for x in img.get_width(): value=maxf(value,img.get_pixel(x,y)[ch])
	return value
func mean_channel(img:Image,ch:int)->float:
	var value:=0.0
	for y in img.get_height():
		for x in img.get_width(): value+=img.get_pixel(x,y)[ch]
	return value/float(img.get_width()*img.get_height())

func difference(a:Image,b:Image)->float:
	var value:=0.0
	for y in a.get_height():
		for x in a.get_width():
			var ac:=a.get_pixel(x,y)
			var bc:=b.get_pixel(x,y)
			value+=absf(ac.r-bc.r)+absf(ac.g-bc.g)+absf(ac.b-bc.b)
	return value/float(a.get_width()*a.get_height()*3)
