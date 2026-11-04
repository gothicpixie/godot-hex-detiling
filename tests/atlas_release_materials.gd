extends SceneTree
const OUT="res://docs/brick_atlas_release/"
const RAW="/tmp/brick-atlas-materials/"
var demo:Node
var surface:MeshInstance3D
var camera:Camera3D
var mat:ShaderMaterial
var corner:Node3D
var records:Array=[]
var descriptor:Dictionary
var material_id:String
var scale_m:=1.4
func _initialize()->void:call_deferred("run")
func mode(arm:String,diagnostic:String="")->void:
	var code:String=FileAccess.get_file_as_string("res://docs/distant_brick/fixtures/v0.7.0.gdshader" if arm=="baseline" else "res://addons/hex_detile/hex_detile.gdshader")
	code=code.replace('#include "coherent_blend.gdshaderinc"',FileAccess.get_file_as_string("res://docs/distant_brick/fixtures/v0.7.0.gdshaderinc" if arm=="baseline" else "res://addons/hex_detile/coherent_blend.gdshaderinc"))
	if diagnostic!="":
		code=code.replace("render_mode diffuse_burley, specular_schlick_ggx;","render_mode unshaded;")
		var body:=""
		if diagnostic=="normal":body="ALBEDO=NORMAL*0.5+0.5;"
		elif diagnostic=="roughness":body="ALBEDO=vec3(ROUGHNESS);"
		elif diagnostic=="protected":
			body="vec3 gn=normalize(geometric_world_normal);vec3 ww=pow(abs(gn),vec3(4));vec2 ux=vec2(axis_sign(gn.x)*world_position.z,-world_position.y)/texture_scale_m;vec2 uy=vec2(-axis_sign(gn.y)*world_position.x,world_position.z)/texture_scale_m;vec2 uz=vec2(axis_sign(gn.z)*world_position.x,world_position.y)/texture_scale_m;float ax=textureGrad(albedo_map,ux,dFdx(ux),dFdy(ux)).a;float ay=textureGrad(albedo_map,uy,dFdx(uy),dFdy(uy)).a;float az=textureGrad(albedo_map,uz,dFdx(uz),dFdy(uz)).a;bool safe=(ww.x<0.000001||ax==0.0)&&(ww.y<0.000001||ay==0.0)&&(ww.z<0.000001||az==0.0);ALBEDO=vec3(safe?0.0:1.0);"
		var last:=code.rfind("}")
		code=code.substr(0,last)+body+code.substr(last)
	var shader:=Shader.new()
	shader.code=code
	mat.shader=shader
	for key in {"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"coherent_blend":true,"use_roughness_map":true,"normal_strength":0.8,"texture_scale_m":scale_m,"structure_period":Vector2.ONE,"structure_stagger":0.0,"variation_seed":0.0,"detile_detrend":0.0,"brick_macro_enabled":false}:
		mat.set_shader_parameter(key,{"detile_enabled":true,"structure_enabled":true,"structure_guard_enabled":true,"structure_guard_in_albedo_alpha":true,"coherent_blend":true,"use_roughness_map":true,"normal_strength":0.8,"texture_scale_m":scale_m,"structure_period":Vector2.ONE,"structure_stagger":0.0,"variation_seed":0.0,"detile_detrend":0.0,"brick_macro_enabled":false}[key])
	mat.set_shader_parameter("albedo_map",load(descriptor.packed_albedo))
	mat.set_shader_parameter("structure_guard_map",load(descriptor.mask))
	mat.set_shader_parameter("brick_individual_enabled",arm!="baseline")
	mat.set_shader_parameter("brick_individual_stochastic",true)
	mat.set_shader_parameter("brick_individual_tiles_per_axis",descriptor.tiles_per_axis)
	mat.set_shader_parameter("brick_individual_map",load(descriptor.atlas))
func shape(name:String)->void:
	corner.visible=name=="corner"
	surface.visible=name!="corner"
	if name=="cylinder":
		var mesh:=CylinderMesh.new()
		mesh.top_radius=2.5;mesh.bottom_radius=2.5;mesh.height=8;mesh.radial_segments=96;mesh.rings=8
		surface.mesh=mesh
	else:
		var wall:=BoxMesh.new();wall.size=Vector3(160,100,0.1);surface.mesh=wall
func pose(p:Vector3,target:Vector3=Vector3.ZERO)->void:
	camera.position=p;camera.look_at(target,Vector3.UP)
func capture()->Image:
	for frame in 2:
		await process_frame
		RenderingServer.force_draw(false)
	return root.get_texture().get_image()
func run()->void:
	DirAccess.make_dir_recursive_absolute(RAW)
	demo=(load("res://demo.tscn") as PackedScene).instantiate();root.add_child(demo)
	await process_frame
	for child in demo.get_children():
		if child is CanvasLayer:child.visible=false
	surface=demo.get_node("Surface");camera=demo.get_node("Camera3D");mat=surface.material_override
	corner=Node3D.new();demo.add_child(corner)
	for axis in 2:
		var node:=MeshInstance3D.new();var mesh:=BoxMesh.new()
		mesh.size=Vector3(8,8,0.1) if axis==0 else Vector3(0.1,8,8)
		node.position=Vector3(-4,0,0) if axis==0 else Vector3(0,0,-4)
		node.mesh=mesh;node.material_override=mat;corner.add_child(node)
	var constants:Dictionary=demo.get_script().get_script_constant_map()
	for index in [17,18]:
		descriptor=constants.BRICK_PRESETS[index]
		material_id=descriptor.packed_albedo.get_file().replace("_albedo_guard.png","")
		scale_m=1.4 if index==17 else 2.0
		demo.set_texture_set(index)
		var source:Array=constants.TEXTURE_SETS[index]
		mat.set_shader_parameter("normal_map",load(source[1]));mat.set_shader_parameter("roughness_map",load(source[2]))
		if "--motion" in OS.get_cmdline_user_args():
			shape("cylinder");camera.projection=Camera3D.PROJECTION_PERSPECTIVE
			for frame in 12:
				var a:=deg_to_rad(20.0+50.0*float(frame)/11.0)
				pose(Vector3(7*cos(a),1.2,7*sin(a)))
				for arm in ["baseline","candidate"]:
					mode(arm);var image:=await capture();var id:String=material_id+"-orbit-"+arm+"-%02d"%frame
					image.save_png(RAW+id+".png");records.append({"id":id,"material":material_id,"shape":"cylinder","frame":frame,"arm":arm,"camera":[camera.position.x,camera.position.y,camera.position.z]})
		else:
			shape("wall");camera.projection=Camera3D.PROJECTION_ORTHOGONAL;pose(Vector3(0,0,40))
			for size_multiplier in [3.0,12.0]:
				camera.size=scale_m*size_multiplier
				var center:=camera.unproject_position(Vector3.ZERO);var next:=camera.unproject_position(Vector3(scale_m,0,0))
				for arm in ["baseline","candidate"]:
					mode(arm,"unlit");var image:=await capture();var id:String=material_id+"-ortho-"+str(size_multiplier)+"-"+arm
					image.save_png(RAW+id+".png");records.append({"id":id,"material":material_id,"kind":"ortho","arm":arm,"size_multiplier":size_multiplier,"source_repeat_px":absf(next.x-center.x),"scale_m":scale_m})
			camera.projection=Camera3D.PROJECTION_PERSPECTIVE
			for mesh in ["wall","corner","cylinder"]:
				shape(mesh)
				if mesh=="wall":pose(Vector3(0.1,0.1,1.6))
				elif mesh=="corner":pose(Vector3(3.5,2,3.5),Vector3(-1,0,-1))
				else:pose(Vector3(4.5,1,5.5))
				for arm in ["baseline","candidate"]:
					mode(arm);var image:=await capture();var id:String=material_id+"-"+mesh+"-"+arm
					image.save_png(RAW+id+".png");records.append({"id":id,"material":material_id,"kind":"shape","shape":mesh,"arm":arm,"scale_m":scale_m})
				for diagnostic in ["protected","normal","roughness"]:
					for arm in ["baseline","candidate"]:
						if diagnostic=="protected" and arm!="baseline":continue
						mode(arm,diagnostic);var image:=await capture();image.save_png(RAW+material_id+"-"+mesh+"-"+diagnostic+"-"+arm+".png")
	FileAccess.open(OUT+("material-motion-settings.json" if "--motion" in OS.get_cmdline_user_args() else "material-capture-settings.json"),FileAccess.WRITE).store_string(JSON.stringify({"records":records,"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"resolution":[root.size.x,root.size.y]},"\t"))
	print("Material cases captured=",records.size());quit()
