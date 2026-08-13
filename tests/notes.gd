extends Node2D

# The notebook fills up over a playthrough. It has to stay on its own page
# and be readable all the way down.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	# everything the game can ever write down, which is the worst case
	for id in Content.ITEMS:
		if Content.ITEMS[id].get("note", "") != "":
			Game.add_note(Content.ITEMS[id]["note"])
	for n in Content.FIXED_NOTES:
		if n.get("note", "") != "":
			Game.add_note(n["note"])
	Game.add_note("Full formula: two cups no-rust, one cup bleach, two and a half "
		+ "cups extinguisher fluid, no water.")
	fails += _expect("a notebook worth scrolling", Game.notes.size() >= 12)

	hud.mode = 3
	hud._notes_y = 0.0
	hud.queue_redraw()
	await get_tree().process_frame

	var band: float = hud.notes_span()
	var total: float = hud.notes_height()
	fails += _expect("it holds more than fits", total > band)

	# down moves through it and stops at the end
	for i in 200:
		hud._notes_key(KEY_DOWN)
		hud.queue_redraw()
		await get_tree().process_frame
	fails += _expect("scrolling down stops at the bottom of the writing",
		hud._notes_y <= total - band + 1.0)
	fails += _expect("and gets there", hud._notes_y > band * 0.5)

	# and back up to the top
	for i in 200:
		hud._notes_key(KEY_UP)
	hud.queue_redraw()
	await get_tree().process_frame
	fails += _expect("scrolling up stops at the top", hud._notes_y <= 0.0)

	# opening it again starts at the top
	hud._notes_y = 400.0
	hud.mode = 0
	hud._unhandled_key_input(_key(KEY_N))
	fails += _expect("opening it starts at the first line", hud._notes_y == 0.0)

	print("NOTES: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
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
