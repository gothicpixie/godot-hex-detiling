# Copied into a fresh extracted addon-only project; uses no repository assets.
extends SceneTree
var mat:ShaderMaterial
func _initialize()->void:call_deferred("run")
func picture()->Image:
	for frame in 3:
		await process_frame
		RenderingServer.force_draw(false)
	return root.get_texture().get_image()
func texture(atlas_tiles:int)->ImageTexture:
	var image:=Image.create(64*atlas_tiles,64*atlas_tiles,false,Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var mortar:=x%16<2 or y%16<2
			var cell_x:=floori(float(x)/64.0);var cell_y:=floori(float(y)/64.0)
			var c:=Color(0.12,0.12,0.12,0) if mortar else Color(0.45+0.04*float((cell_x+cell_y)%4),0.18+0.03*float(cell_x%3),0.08+0.02*float(cell_y%3),1)
			image.set_pixel(x,y,c)
	image.generate_mipmaps();return ImageTexture.create_from_image(image)
func flat(c:Color)->ImageTexture:
	var image:=Image.create(8,8,false,Image.FORMAT_RGBA8);image.fill(c);image.generate_mipmaps();return ImageTexture.create_from_image(image)
func maximum(a:Image,b:Image)->int:
	var x:=a.get_data();var y:=b.get_data();var result:=0
	for i in x.size():result=maxi(result,absi(int(x[i])-int(y[i])))
	return result
func run()->void:
	var world:=Node3D.new();root.add_child(world)
	var box:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(4,4,0.2);box.mesh=mesh;world.add_child(box)
	mat=ShaderMaterial.new();mat.shader=load("res://addons/hex_detile/hex_detile.gdshader");box.material_override=mat
	for key in {"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"structure_period":Vector2.ONE,"coherent_blend":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"variation_seed":0.0,"brick_individual_stochastic":true}:
		mat.set_shader_parameter(key,{"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"structure_period":Vector2.ONE,"coherent_blend":true,"texture_scale_m":2.5,"normal_strength":0.8,"use_roughness_map":true,"variation_seed":0.0,"brick_individual_stochastic":true}[key])
	mat.set_shader_parameter("albedo_map",texture(1));mat.set_shader_parameter("normal_map",flat(Color(0.5,0.5,1,1)));mat.set_shader_parameter("roughness_map",flat(Color(0.7,0.7,0.7,1)))
	var camera:=Camera3D.new();camera.position=Vector3(0,0,6);world.add_child(camera);camera.look_at(Vector3.ZERO,Vector3.UP);camera.current=true
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-20,-20,0);world.add_child(light)
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color(0.04,0.05,0.08);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=1.0;environment.environment=env;world.add_child(environment)
	mat.set_shader_parameter("brick_individual_enabled",false);var baseline:=await picture()
	mat.set_shader_parameter("brick_individual_map",texture(4));mat.set_shader_parameter("brick_individual_enabled",true);var default_four:=await picture()
	mat.set_shader_parameter("brick_individual_tiles_per_axis",4);var explicit_four:=await picture()
	mat.set_shader_parameter("brick_individual_tiles_per_axis",2);mat.set_shader_parameter("brick_individual_map",texture(2));var two:=await picture()
	var different:=maximum(baseline,default_four);var default_delta:=maximum(default_four,explicit_four);var two_diff:=maximum(baseline,two)
	var result:={"default4_vs_explicit4_max_byte_delta":default_delta,"feature4_vs_off_max_byte_delta":different,"feature2_vs_off_max_byte_delta":two_diff,"resolution":[root.size.x,root.size.y],"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"fresh_project":true,"repository_assets_used":false,"pass":default_delta==0 and different>1 and two_diff>1}
	FileAccess.open("res://fresh-smoke-result.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));explicit_four.save_png("res://fresh-smoke.png");print(JSON.stringify(result));quit(0 if result["pass"] else 1)
