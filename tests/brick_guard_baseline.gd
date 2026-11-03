# Full spatial shader (including triplanar fragment) versus frozen 6c9cabf.
extends SceneTree
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
	mat.set_shader_parameter("structure_guard_enabled",false)
	var current:Shader=mat.shader
	var baseline:=Shader.new()
	baseline.code=FileAccess.get_file_as_string("/tmp/hex-brick-guard-baseline.gdshader").replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string("/tmp/hex-brick-guard-baseline.gdshaderinc"))
	var failures:=0
	for structured in [false,true]:
		for seed in [0.0,7.0]:
			mat.set_shader_parameter("structure_enabled",structured)
			mat.set_shader_parameter("variation_seed",seed)
			mat.shader=current
			var a:=await capture()
			mat.shader=baseline
			var b:=await capture()
			var max_delta:=0.0
			for y in a.get_height():
				for x in a.get_width():
					var ca:=a.get_pixel(x,y)
					var cb:=b.get_pixel(x,y)
					max_delta=maxf(max_delta,maxf(absf(ca.r-cb.r),maxf(absf(ca.g-cb.g),absf(ca.b-cb.b))))
			print("PASS: " if max_delta<0.008 else "FAIL: ","full spatial disabled guard old 6c9cabf structure=",structured," seed=",seed," max RGB delta=",max_delta)
			if max_delta>=0.008: failures+=1
	quit(1 if failures else 0)
func capture()->Image:
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
