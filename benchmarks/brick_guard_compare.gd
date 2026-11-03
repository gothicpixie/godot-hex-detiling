extends SceneTree
const WARMUP:=60
const SAMPLES:=180
func _initialize()->void: call_deferred("run")
func run()->void:
	var demo:Node=(load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer: child.visible=false
	demo.set_texture_set(3)
	demo.set_structure(true)
	var mat:ShaderMaterial=demo.get_node("Surface").material_override
	mat.set_shader_parameter("coherent_blend",true)
	mat.set_shader_parameter("detile_enabled",true)
	mat.set_shader_parameter("texture_scale_m",2.5)
	mat.set_shader_parameter("use_roughness_map",true)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var records:Array=[]
	for round_index in 3:
		for guarded in ([false,true] if round_index%2==0 else [true,false]):
			mat.set_shader_parameter("structure_guard_enabled",guarded)
			for frame in WARMUP: await process_frame
			var times:Array[float]=[]
			var gpu_samples:=0
			var previous:=Time.get_ticks_usec()
			for frame in SAMPLES:
				await process_frame
				var current:=Time.get_ticks_usec()
				times.append(float(current-previous)/1000.0)
				previous=current
				if RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())>0: gpu_samples+=1
			times.sort()
			var total:=0.0
			for t in times: total+=t
			var record:={"round":round_index,"guarded":guarded,"frames":SAMPLES,"median_whole_frame_ms":times[SAMPLES/2],"p95_whole_frame_ms":times[int(SAMPLES*0.95)],"mean_whole_frame_ms":total/SAMPLES,"gpu_timer_nonzero_samples":gpu_samples}
			records.append(record)
			print(JSON.stringify(record))
	print("RESULTS_JSON="+JSON.stringify(records))
	quit()
