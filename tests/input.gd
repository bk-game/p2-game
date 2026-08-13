extends Node2D

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var fog = get_tree().get_first_node_in_group("light")
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	fails += _expect("there is light to see by", fog.enabled == true)

	await _press(KEY_I)
	fails += _expect("I opens the bag", hud.mode == 2)
	fails += _expect("bag blocks movement", hud.blocking())
	await _press(KEY_I)
	fails += _expect("I closes the bag", hud.mode == 0)

	await _press(KEY_N)
	fails += _expect("N opens the notebook", hud.mode == 3)
	await _press(KEY_N)
	await _press(KEY_R)
	fails += _expect("R opens the report", hud.mode == 4)
	await _press(KEY_R)
	fails += _expect("back to play", hud.mode == 0)

	print("INPUT: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _press(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
	Input.flush_buffered_events()
	await get_tree().process_frame
	await get_tree().process_frame

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
