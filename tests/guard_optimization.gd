# Deterministic production-vs-frozen GPU readback and sequential ablation timing.
extends SceneTree
const OUT="res://docs/guard_optimization/"
var demo:Node
var mat:ShaderMaterial
var surface:MeshInstance3D
var camera:Camera3D
var terrain:Mesh
var shaders:Dictionary={}
var records:Array=[]
var failures:=0
var post_draw_count:=0
func _initialize()->void: call_deferred("run")
func source_shader(frozen:bool)->String:
	var path:=OUT+"fixtures/v0.6.0" if frozen else "res://addons/hex_detile/coherent_blend"
	var code:=FileAccess.get_file_as_string(OUT+"fixtures/v0.6.0.gdshader" if frozen else "res://addons/hex_detile/hex_detile.gdshader")
	return code.replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string(path+".gdshaderinc"))
func make_shader(code:String)->Shader:
	var s:=Shader.new()
	s.code=code
	return s
func run()->void:
	print("ENGINE=",Engine.get_version_info()," GPU=",RenderingServer.get_video_adapter_name()," renderer=",RenderingServer.get_current_rendering_method())
	demo=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	demo.set_texture_set(3)
	demo.set_structure(true)
	surface=demo.get_node("Surface")
	camera=demo.get_node("Camera3D")
	terrain=surface.mesh
	mat=surface.material_override
	var current:=source_shader(false)
	if not "structure_guard_in_albedo_alpha" in current:
		print("FAIL: optimized packing interface absent (expected RED)")
		quit(1)
		return
	shaders["frozen"]=make_shader(source_shader(true))
	shaders["both"]=make_shader(current)
	# Test-only preprocessor variants are derived from production source.
	var begin:=current.find("// GUARD_SOURCE_ONLY_BEGIN")
	var end:=current.find("// GUARD_SOURCE_ONLY_END")
	assert(current.count("// GUARD_SOURCE_ONLY_BEGIN")==1 and current.count("// GUARD_SOURCE_ONLY_END")==1)
	var pack_code:=current
	if begin>=0 and end>=begin: pack_code=current.substr(0,begin)+current.substr(end+"// GUARD_SOURCE_ONLY_END".length())
	assert(pack_code!=current and not "if (guard_detail == 0.0 || reference_mask == 0.0)" in pack_code)
	shaders["pack"]=make_shader(pack_code)
	shaders["early"]=shaders.both
	for key in {"coherent_blend":true,"detile_enabled":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"blend_contrast":0.65,"detile_detrend":0.0,"structure_guard_enabled":true}:
		mat.set_shader_parameter(key,{"coherent_blend":true,"detile_enabled":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"blend_contrast":0.65,"detile_detrend":0.0,"structure_guard_enabled":true}[key])
	if "--bench" in OS.get_cmdline_user_args(): await benchmark()
	elif "--approach-only" in OS.get_cmdline_user_args(): await motion_checks()
	else:
		await spatial_checks()
		await motion_checks()
	FileAccess.open(OUT+("benchmark.json" if "--bench" in OS.get_cmdline_user_args() else ("approach-equivalence.json" if "--approach-only" in OS.get_cmdline_user_args() else "equivalence.json")),FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":[root.size.x,root.size.y],"readback":"RGBA8","frame_tolerance_max":2.0/255.0,"records":records,"failures":failures},"\t"))
	quit(1 if failures else 0)
func mode(name:String)->void:
	mat.shader=shaders[name]
	var packed:=name=="both" or name=="pack"
	mat.set_shader_parameter("structure_guard_in_albedo_alpha",packed)
	mat.set_shader_parameter("albedo_map",load("res://assets/gallery/brick_4_albedo_guard.png" if packed else "res://assets/gallery/brick_4_albedo.jpg"))
	mat.set_shader_parameter("structure_guard_map",load("res://assets/gallery/brick_4_interior_mask.png"))
func wall()->void:
	var mesh:=BoxMesh.new()
	mesh.size=Vector3(14,8,1)
	surface.mesh=mesh
func pose(p:Vector3)->void:
	camera.position=p
	camera.look_at(Vector3.ZERO,Vector3.UP)
func capture()->Image:
	for frame in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func delta(a:Image,b:Image)->Dictionary:
	var aa:=a.get_data()
	var bb:=b.get_data()
	var maximum:=0.0
	var total:=0.0
	var square:=0.0
	var count:=0
	for i in aa.size():
		if i%4==3: continue
		var d:=absf(float(aa[i])-float(bb[i]))/255.0
		maximum=maxf(maximum,d)
		total+=d
		square+=d*d
		count+=1
	return {"max":maximum,"mean":total/count,"rmse":sqrt(square/count)}
func spatial_checks()->void:
	wall()
	for position in [Vector3(1,1,8),Vector3(12,1,2),Vector3(1,1,45)]:
		pose(position)
		for seed in [0.0,7.0]:
			mat.set_shader_parameter("variation_seed",seed)
			for enabled in [false,true]:
				mat.set_shader_parameter("structure_guard_enabled",enabled)
				for maps in [false,true]:
					mat.set_shader_parameter("normal_strength",0.8 if maps else 0.0)
					mat.set_shader_parameter("use_roughness_map",maps)
					for detrend in [0.0,0.6]:
						mat.set_shader_parameter("detile_detrend",detrend)
						mode("frozen")
						var a:=await capture()
						mode("both")
						var b:=await capture()
						var d:=delta(a,b)
						var ok:bool=d.max<=2.0/255.0
						if not ok: failures+=1
						var entry:={"test":"spatial","camera":[position.x,position.y,position.z],"seed":seed,"guard":enabled,"maps":maps,"detrend":detrend,"delta":d,"pass":ok}
						records.append(entry)
						print(JSON.stringify(entry))
func motion_checks()->void:
	mat.set_shader_parameter("structure_guard_enabled",true)
	mat.set_shader_parameter("normal_strength",0.8)
	mat.set_shader_parameter("use_roughness_map",true)
	mat.set_shader_parameter("detile_detrend",0.0)
	for trajectory in (["approach-retreat"] if "--approach-only" in OS.get_cmdline_user_args() else ["wall-pan","approach-retreat","grazing","terrain"]):
		if trajectory=="terrain": surface.mesh=terrain
		else: wall()
		for seed in [0.0,7.0]:
			mat.set_shader_parameter("variation_seed",seed)
			var directory:String="/tmp/guard-optimization-motion/"+trajectory+"-seed"+str(int(seed))
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
			for frame in 48:
				var t:=float(frame)/47.0
				if trajectory=="wall-pan": pose(Vector3(-4.0+8.0*t,0.8,8))
				elif trajectory=="approach-retreat": pose(Vector3(0.1,0.1,1.5*pow(80.0,sin(t*PI))))
				elif trajectory=="grazing": pose(Vector3(8.0+6.0*t,1,3.0-1.5*t))
				else: pose(Vector3(8.0*cos(t*PI*0.6),6.0+4.0*t,10.0*sin(t*PI*0.6)+3.0))
				mode("frozen")
				var a:=await capture()
				mode("both")
				var b:=await capture()
				a.save_png(directory+"/old-%03d.png"%frame)
				b.save_png(directory+"/new-%03d.png"%frame)
				var d:=delta(a,b)
				if d.max>2.0/255.0: failures+=1
				records.append({"test":"motion","trajectory":trajectory,"seed":seed,"frame":frame,"camera":[camera.position.x,camera.position.y,camera.position.z],"delta":d})
			print("motion captured ",trajectory," seed=",seed)
func benchmark()->void:
	RenderingServer.frame_post_draw.connect(func(): post_draw_count+=1)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for scene in ["terrain","close-wall","distant"]:
		if scene=="terrain":
			surface.mesh=terrain
			pose(Vector3(9,6,10))
		else:
			wall()
			pose(Vector3(1,1,8 if scene=="close-wall" else 120))
		for round_index in 3:
			var order:Array=["frozen","pack","early","both"] if round_index==0 else (["both","early","pack","frozen"] if round_index==1 else ["early","frozen","both","pack"])
			for variant in order:
				mode(variant)
				for frame in 180:
					await process_frame
					RenderingServer.force_draw(false)
				var times:Array[float]=[]
				var nonzero:=0
				var draw_count_before:=post_draw_count
				for frame in 600:
					await process_frame
					var draw_start:=Time.get_ticks_usec()
					RenderingServer.force_draw(false)
					var now:=Time.get_ticks_usec()
					times.append(float(now-draw_start)/1000.0)
					if RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())>0: nonzero+=1
				times.sort()
				var total:=0.0
				for sample in times: total+=sample
				var entry:={"test":"benchmark","scene":scene,"round":round_index,"variant":variant,"warmup":180,"samples":600,"median_draw_call_ms":times[300],"p95_draw_call_ms":times[570],"mean_draw_call_ms":total/600.0,"gpu_timer_nonzero":nonzero,"frame_post_draw_callbacks":post_draw_count-draw_count_before,"draw_calls_in_frame":RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)}
				if entry.frame_post_draw_callbacks!=600 or entry.draw_calls_in_frame<1: failures+=1
				records.append(entry)
				print(JSON.stringify(entry))
