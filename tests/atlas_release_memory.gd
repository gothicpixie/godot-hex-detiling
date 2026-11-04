# Fresh process, one gallery texture: engine accounting and process RSS, separately labeled.
extends SceneTree
func _initialize()->void: call_deferred("run")
func rss_bytes()->int:
	var result:Array=[]
	OS.execute("ps",["-o","rss=","-p",str(OS.get_process_id())],result)
	return int(str(result[0]).strip_edges())*1024 if not result.is_empty() else -1
func run()->void:
	var arm:=OS.get_cmdline_user_args()[0]
	var texrect:=TextureRect.new()
	texrect.size=Vector2(256,256)
	texrect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.add_child(texrect)
	for frame in 10:
		await process_frame
		RenderingServer.force_draw(false)
	var before:=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	var rss_before:=rss_bytes()
	var path:String="res://assets/gallery/brick_4_albedo_guard.png" if arm=="baseline" else ("res://assets/gallery/brick_4_individual_atlas_seed0.png" if arm=="four" else ("res://assets/gallery/brick_4_individual_atlas_3x3_balanced_seed0.png" if arm=="three" else ("res://assets/gallery/brick_4_individual_atlas_2x2_balanced_seed0.png" if arm=="balanced" else "res://assets/gallery/brick_4_individual_atlas_2x2_seed0.png")))
	texrect.texture=load(path)
	for frame in 30:
		await process_frame
		RenderingServer.force_draw(false)
	var after:=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	var row:={"arm":arm,"path":path,"fresh_process":true,"engine_texture_memory_before_bytes":before,"engine_texture_memory_after_bytes":after,"engine_texture_memory_increment_bytes":after-before,"process_RSS_before_bytes":rss_before,"process_RSS_after_bytes":rss_bytes(),"width":texrect.texture.get_width(),"height":texrect.texture.get_height(),"accounting":"RenderingServer texture memory metric; process RSS is process resident memory; neither establishes physical VRAM residency","gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()}
	var image:=texrect.texture.get_image()
	row["imported_mipmap_count"]=image.get_mipmap_count()
	row["imported_image_data_bytes"]=image.get_data().size()
	row["native_texture_size"]=Vector2i(texrect.texture.get_width(),texrect.texture.get_height())
	FileAccess.open("res://docs/brick_atlas_release/memory-"+arm+".json",FileAccess.WRITE).store_string(JSON.stringify(row,"\t"))
	print(JSON.stringify(row))
	quit()
