# Isolated sequential synchronous draw-call intervals, not FPS or isolated GPU duration.
extends SceneTree
const OUT="res://docs/brick_atlas_release/"
var callbacks:=0
var records:Array=[]
func _initialize()->void: call_deferred("run")
func shader_at(path:String,include_path:String)->Shader:
	var shader:=Shader.new()
	shader.code=FileAccess.get_file_as_string(path).replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string(include_path))
	return shader
func run()->void:
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	demo.set_texture_set(3)
	demo.set_structure(true)
	var surface:MeshInstance3D=demo.get_node("Surface")
	var camera:Camera3D=demo.get_node("Camera3D")
	var mat:ShaderMaterial=surface.material_override
	var shaders:Dictionary={"baseline":shader_at("res://docs/distant_brick/fixtures/v0.7.0.gdshader","res://docs/distant_brick/fixtures/v0.7.0.gdshaderinc"),"four":shader_at(OUT+"fixtures/accepted-4x.gdshader",OUT+"fixtures/accepted-4x.gdshaderinc"),"balanced":load("res://addons/hex_detile/hex_detile.gdshader")}
	for key in {"coherent_blend":true,"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"blend_contrast":0.65,"detile_detrend":0.0,"brick_macro_enabled":false,"variation_seed":0.0}:
		mat.set_shader_parameter(key,{"coherent_blend":true,"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"blend_contrast":0.65,"detile_detrend":0.0,"brick_macro_enabled":false,"variation_seed":0.0}[key])
	mat.set_shader_parameter("albedo_map",load("res://assets/gallery/brick_4_albedo_guard.png"))
	RenderingServer.frame_post_draw.connect(func(): callbacks+=1)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for scene in ["close-wall","distant-wall","sphere"]:
		if scene=="sphere":
			var sphere:=SphereMesh.new()
			sphere.radius=6
			sphere.height=12
			sphere.radial_segments=96
			sphere.rings=48
			surface.mesh=sphere
			camera.position=Vector3(0,1,16)
		else:
			var wall:=BoxMesh.new()
			wall.size=Vector3(160,100,1)
			surface.mesh=wall
			camera.position=Vector3(0.1,0.1,2 if scene=="close-wall" else 32)
		camera.look_at(Vector3.ZERO,Vector3.UP)
		for round_index in 3:
			var order:Array=["baseline","four","balanced"] if round_index==0 else (["balanced","four","baseline"] if round_index==1 else ["four","baseline","balanced"])
			for arm in order:
				mat.shader=shaders[arm]
				mat.set_shader_parameter("brick_individual_enabled",arm!="baseline")
				mat.set_shader_parameter("brick_individual_stochastic",true)
				mat.set_shader_parameter("brick_individual_tiles_per_axis",2 if arm=="balanced" else 4)
				mat.set_shader_parameter("brick_individual_map",null if arm=="baseline" else load("res://assets/gallery/brick_4_individual_atlas_"+("2x2_balanced_" if arm=="balanced" else "")+"seed0.png"))
				for frame in 90:
					if frame%4==0: await process_frame
					RenderingServer.force_draw(false)
				var times:Array[float]=[]
				var before:=callbacks
				var nonzero:=0
				var actual_nonzero_draw_frames:=0
				for frame in 240:
					if frame%4==0: await process_frame
					var start:=Time.get_ticks_usec()
					RenderingServer.force_draw(false)
					times.append(float(Time.get_ticks_usec()-start)/1000.0)
					if RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)>0: actual_nonzero_draw_frames+=1
					if RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())>0:nonzero+=1
				times.sort()
				var total:=0.0
				for t in times:total+=t
				var row:={"scene":scene,"round":round_index,"arm":arm,"warmup":90,"samples":240,"forced_draw_batch":4,"median_draw_call_ms":times[120],"p95_draw_call_ms":times[228],"mean_draw_call_ms":total/240,"actual_draw_callbacks":callbacks-before,"draw_calls_in_frame":RenderingServer.viewport_get_render_info(root.get_viewport_rid(),RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),"gpu_timer_nonzero_samples":nonzero,"measured_frames_with_nonzero_drawcalls":actual_nonzero_draw_frames}
				assert(callbacks-before==240 and actual_nonzero_draw_frames==240)
				records.append(row)
				print(JSON.stringify(row))
	FileAccess.open(OUT+"benchmark.json",FileAccess.WRITE).store_string(JSON.stringify({"resolution":[root.size.x,root.size.y],"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"metric":"synchronous force_draw(false) interval excluding process_frame wait; not FPS or GPU time","records":records},"\t"))
	quit()
