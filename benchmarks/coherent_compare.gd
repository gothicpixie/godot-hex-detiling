extends SceneTree

# Alternate modes to reduce bias from warm-up and changing GPU clocks.
const WARMUP_FRAMES := 180
const SAMPLE_FRAMES := 600
const ROUNDS := 9

func _initialize() -> void:
	call_deferred("run_benchmark")

func run_benchmark() -> void:
	var demo := (load("res://demo.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	# Eliminate UI drawing from the measurement; retain the demo surface and light.
	for child in demo.get_children():
		if child is CanvasLayer:
			child.visible = false
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var material: ShaderMaterial = demo.get_node("Surface").material_override
	material.set_shader_parameter("rotation_strength", 0.65)
	material.set_shader_parameter("blend_contrast", 0.65)
	material.set_shader_parameter("use_roughness_map", true)
	var records: Array = []
	for round_index in ROUNDS:
		var mode: String = ["shared", "paper", "coherent"][round_index % 3]
		demo.set_detile(mode != "periodic")
		material.set_shader_parameter("paper_blend", mode == "paper")
		material.set_shader_parameter("coherent_blend", mode == "coherent")
		for i in WARMUP_FRAMES:
			await process_frame
		var times: Array[float] = []
		var gpu_times: Array[float] = []
		var previous := Time.get_ticks_usec()
		for i in SAMPLE_FRAMES:
			await process_frame
			var current := Time.get_ticks_usec()
			times.append((current - previous) / 1000.0)
			previous = current
			var gpu := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
			if gpu > 0.0:
				gpu_times.append(gpu)
		times.sort()
		gpu_times.sort()
		var record := {"mode": mode, "frames": SAMPLE_FRAMES, "median_frame_ms": times[SAMPLE_FRAMES / 2], "p95_frame_ms": times[int(SAMPLE_FRAMES * 0.95)], "mean_frame_ms": average(times), "gpu_samples": gpu_times.size()}
		if not gpu_times.is_empty():
			record["median_gpu_ms"] = gpu_times[gpu_times.size() / 2]
		records.append(record)
		print(JSON.stringify(record))
	print("RESULTS_JSON=" + JSON.stringify(records))
	quit()

func average(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / values.size()
