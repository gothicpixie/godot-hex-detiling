extends SceneTree
var vp:SubViewport
var mat:ShaderMaterial
var records:Array=[]
var failures:=0
func _initialize()->void: call_deferred("run")
func run()->void:
	vp=SubViewport.new()
	vp.size=Vector2i(256,256)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rect:=ColorRect.new()
	rect.size=Vector2(256,256)
	vp.add_child(rect)
	mat=ShaderMaterial.new()
	rect.material=mat
	mat.set_shader_parameter("original",load("res://assets/gallery/brick_4_albedo.jpg"))
	mat.set_shader_parameter("packed",load("res://assets/gallery/brick_4_albedo_guard.png"))
	mat.set_shader_parameter("mask",load("res://assets/gallery/brick_4_interior_mask.png"))
	for lod in [0.0,1.0,2.0,3.0,5.0,10.0]:
		for grazing in [false,true]:
			var shader:=Shader.new()
			shader.code="shader_type canvas_item; uniform sampler2D original:source_color,filter_linear_mipmap_anisotropic,repeat_enable; uniform sampler2D packed:source_color,filter_linear_mipmap_anisotropic,repeat_enable; uniform sampler2D mask:filter_linear_mipmap_anisotropic,repeat_enable; void fragment(){vec2 p=UV*2.0-vec2(0.17,0.31);vec2 dx=vec2("+str(pow(2,lod)/1024.0)+",0);vec2 dy=vec2(0,"+str(pow(2,lod)/1024.0*(0.0625 if grazing else 1.0))+");vec4 a=textureGrad(packed,p,dx,dy);vec3 b=textureGrad(original,p,dx,dy).rgb;float m=textureGrad(mask,p,dx,dy).r;COLOR=vec4(max(max(abs(a.r-b.r),abs(a.g-b.g)),abs(a.b-b.b))*32.0,abs(a.a-m)*32.0,0,1);}"
			mat.shader=shader
			for frame in 3:
				await process_frame
				await RenderingServer.frame_post_draw
			var img:=vp.get_texture().get_image()
			var rgb:=0.0
			var alpha:=0.0
			for y in img.get_height():
				for x in img.get_width():
					var c:=img.get_pixel(x,y)
					rgb=maxf(rgb,c.r/32.0)
					alpha=maxf(alpha,c.g/32.0)
			var ok:=rgb<=1.0/(255.0*32.0) and alpha<=1.0/(255.0*32.0)
			if not ok: failures+=1
			var row:={"lod":lod,"grazing_16_to_1":grazing,"max_rgb_linear_error":rgb,"max_alpha_error":alpha,"quantization":1.0/(255.0*32.0),"pass":ok}
			records.append(row)
			print(JSON.stringify(row))
	FileAccess.open("res://docs/guard_optimization/import-gpu.json",FileAccess.WRITE).store_string(JSON.stringify({"gpu":RenderingServer.get_video_adapter_name(),"records":records,"failures":failures},"\t"))
	quit(1 if failures else 0)
