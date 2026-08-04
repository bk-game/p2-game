extends SceneTree


func _initialize() -> void:
	await process_frame
	await process_frame
	var music := get_root().get_node_or_null("Music")
	print("music_autoload=", music)
	if music:
		for c in music.get_children():
			print("child=", c, " playing=", c.playing, " stream=", c.stream, " db=", c.volume_db, " bus=", c.bus)
	print("master_mute=", AudioServer.is_bus_mute(0), " master_db=", AudioServer.get_bus_volume_db(0))
	print("driver=", AudioServer.get_driver_name(), " output=", AudioServer.get_output_device())
	quit()
