# Real production helper: fixed-world mip/fade and triangle boundary continuity.
extends SceneTree
var vp:SubViewport
var mat:ShaderMaterial
var prefix:String
var records:Array=[]
var failures:=0
func _initialize()->void: call_deferred("run")
func render(body:String)->Image:
	var shader:=Shader.new()
	shader.code=prefix+"void fragment(){"+body+"}"
	mat.shader=shader
	await process_frame
	RenderingServer.force_draw(false)
	return vp.get_texture().get_image()
func max_rgb(image:Image)->float:
	var maximum:=0.0
	for y in image.get_height():
		for x in image.get_width():
			var c:=image.get_pixel(x,y)
			maximum=maxf(maximum,maxf(c.r,maxf(c.g,c.b)))
	return maximum
func run()->void:
	prefix=FileAccess.get_file_as_string("res://addons/hex_detile/hex_detile.gdshader").split("void vertex()")[0].replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string("res://addons/hex_detile/coherent_blend.gdshaderinc")).replace("shader_type spatial;","shader_type canvas_item;").replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
	assert(not "TIME" in prefix)
	vp=SubViewport.new()
	vp.size=Vector2i(128,128)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rect:=ColorRect.new()
	rect.size=Vector2(128,128)
	vp.add_child(rect)
	mat=ShaderMaterial.new()
	rect.material=mat
	mat.set_shader_parameter("brick_individual_stochastic",true)
	for seed in [0.0,7.0]:
		mat.set_shader_parameter("variation_seed",seed)
		mat.set_shader_parameter("brick_individual_map",load("res://assets/gallery/brick_4_individual_atlas_seed"+str(int(seed))+".png"))
		# Around mip integer LODs and both coarse-fade endpoints.
		for footprint in [1.0/1024.0,2.0/1024.0,4.0/1024.0,8.0/1024.0,16.0/1024.0,32.0/1024.0,64.0/1024.0,0.125/sqrt(3.0),0.15,0.5/sqrt(3.0),0.35]:
			var body:="vec2 p=UV*8.0-vec2(4.17,4.31);vec3 mean_color=textureLod(brick_individual_map,vec2(0.5),16.0).rgb;float fp="+str(footprint)+";vec2 da=vec2(fp*(1.0-0.0001),0);vec2 db=vec2(fp*(1.0+0.0001),0);vec3 a=brick_individual_color(p,da,da.yx,mean_color);vec3 b=brick_individual_color(p,db,db.yx,mean_color);COLOR=vec4(abs(a-b)*32.0,1);"
			var error:=max_rgb(await render(body))/32.0
			if error>1.0/255.0: failures+=1
			records.append({"test":"fixed_world_footprint_continuity","seed":seed,"source_uv_per_pixel":footprint,"footprint_relative_epsilon":0.0001,"max_linear_rgb_delta":error,"tolerance":1.0/255.0})
		for edge in ["diagonal","vertical","horizontal"]:
			var f:String="vec2(t,1.0-t)" if edge=="diagonal" else ("vec2(0,t)" if edge=="vertical" else "vec2(t,0)")
			var body:="vec2 base=floor(UV*16.0)-vec2(8);float t=fract(UV.x*16.0);vec2 sk=base+"+f+";float sy=sk.y/1.15470054;vec2 p=vec2(sk.x+0.57735027*sy,sy)/sqrt(3.0);vec2 e="+("vec2(0,0.000001)" if edge=="horizontal" else "vec2(0.000001,0)")+";vec3 mean_color=vec3(0);vec2 dx=vec2(0.0001,0),dy=vec2(0,0.0001);vec3 a=brick_individual_color(p-e,dx,dy,mean_color);vec3 b=brick_individual_color(p+e,dx,dy,mean_color);COLOR=vec4(abs(a-b)*32.0,1);"
			var error:=max_rgb(await render(body))/32.0
			if error>2.0/255.0: failures+=1
			records.append({"test":"actual_triangle_boundary","seed":seed,"edge":edge,"source_uv_epsilon":0.000001,"max_linear_rgb_delta":error,"tolerance":2.0/255.0})
		for footprint in [0.05,0.15,0.35]:
			var image:=await render("float fp="+str(footprint)+";float d=brick_individual_detail(vec2(fp,0),vec2(0,fp));COLOR=vec4(vec3(d),1);")
			records.append({"test":"actual_gpu_coarse_fade_coverage","seed":seed,"source_uv_per_pixel":footprint,"gpu_detail_readback":image.get_pixel(64,64).r})
	FileAccess.open("res://docs/individual_brick/continuity.json",FileAccess.WRITE).store_string(JSON.stringify({"points_per_case":16384,"readback":"RGBA8 error amplified32","quantization":1.0/(255.0*32.0),"no_TIME_phase":true,"failures":failures,"records":records},"\t"))
	print("Continuity failures=",failures)
	quit(1 if failures else 0)
