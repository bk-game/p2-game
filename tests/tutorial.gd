extends Node2D

# The game opens on a card, and the first minute teaches itself: each step
# waits for the thing it asked for and moves on when it lands.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var pl = get_tree().get_first_node_in_group("player")
	var fails := 0

	fails += _expect("it opens on the title card", hud.mode == 10)
	fails += _expect("and nothing moves behind it", hud.blocking())
	hud._unhandled_key_input(_key(KEY_SPACE))
	fails += _expect("any key gets you onto the floor", hud.mode == 0)
	fails += _expect("and the first thing it asks for is walking", hud._step == 0)

	# walking
	for i in 30:
		pl.global_position += Vector2(8, 0)
		hud._teaching(0.1)
	fails += _expect("walking about moves it on", hud._step == 1)

	# using something
	hud._teaching(0.5)
	Game.acted.emit()
	hud._teaching(0.5)
	fails += _expect("using a thing moves it on", hud._step == 2)

	# carrying something
	Game.inventory.append("docket")
	hud._teaching(0.5)
	fails += _expect("picking something up moves it on", hud._step == 3)

	# the inventory, then the notebook
	hud.mode = 2
	hud._teaching(0.5)
	fails += _expect("opening the inventory moves it on", hud._step == 4)
	hud.mode = 3
	hud._teaching(0.5)
	fails += _expect("the notebook is the last of it", hud._step == 5)
	fails += _expect("and then it is done", hud._step >= hud.STEPS.size())

	# and it can be walked out of
	hud._step = 1
	hud.mode = 0
	hud._unhandled_key_input(_key(KEY_ESCAPE))
	fails += _expect("escape skips the rest of it", hud._step >= hud.STEPS.size())

	print("TUTORIAL: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
