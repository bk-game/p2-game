extends Node2D

# The day starts in the office and has to end there. The door out puts you on
# the cabin's doorstep; the cabin's front door only brings you back once you
# have what you were sent for, and says so when you have.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var pl = get_tree().get_first_node_in_group("player")
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	fails += _expect("you start in the office",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)

	var out = null
	var home = null
	for n in get_tree().get_nodes_in_group("act"):
		if n.get("label") == "Out to the job":
			out = n
		elif n.get("label") == "Back to the office":
			home = n
	fails += _expect("a way out and a way back", out != null and home != null)

	out.act()
	fails += _expect("the door out puts you on the doorstep",
		pl.global_position.distance_to(Content.ENTRANCE) < 1.0)

	home.act()
	fails += _expect("and you cannot go back empty-handed",
		pl.global_position.distance_to(Content.ENTRANCE) < 1.0)
	fails += _expect("which the prompt says", home.prompt().contains("Not done"))

	# find him, then take the certificates
	Game.set_flag("found_body")
	fails += _expect("the body alone is not the job", not Game.flag("can_leave"))
	Game.add_item("death_certs")
	fails += _expect("both together is", Game.flag("can_leave"))
	fails += _expect("and it says so", hud.mode == 1)
	fails += _expect("without eating what you just picked up",
		hud._body.contains("certificates") or hud._queued.size() == 1)

	hud._unhandled_key_input(_key(KEY_E))
	hud._unhandled_key_input(_key(KEY_E))
	fails += _expect("the popup names the way out",
		Game.notes[Game.notes.size() - 1].contains("way you came in"))

	home.act()
	fails += _expect("and now the front door takes you home",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)

	print("TRAVEL: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
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
