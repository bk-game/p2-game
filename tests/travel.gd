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

	var boss = null
	var door = null
	var home = null
	var oyelaran = null
	for n in get_tree().get_nodes_in_group("act"):
		if n.get("kind") == "boss":
			boss = n
		elif n.has_method("prompt") and n.prompt().begins_with("Out to the yard"):
			door = n
		elif n.get("label") == "Back to the office":
			home = n
		elif n.get("data") != null and n.data.get("name", "") == "Oyelaran":
			oyelaran = n
	fails += _expect("a lift, a door out, a way back and somebody with the keys",
		boss != null and door != null and home != null and oyelaran != null)

	boss.act()
	_dismiss(hud)
	fails += _expect("the boss will not see you yet",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)

	door.act()
	_dismiss(hud)
	fails += _expect("and the door will not open with no job",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)

	# read the job off the board: it names what you sign out with
	for n in get_tree().get_nodes_in_group("act"):
		if n.has_method("prompt") and n.prompt() == "Read the job on the board":
			n.act()
	_dismiss(hud)
	fails += _expect("reading the board is what starts the day",
		Game.flag("read_job"))

	door.act()
	_dismiss(hud)
	fails += _expect("the door still wants the kit",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)
	fails += _expect("and says what is missing first",
		door.prompt().contains("docket"))

	# the docket off the board and the lamp out of the store
	Game.add_item("docket")
	_dismiss(hud)
	Game.add_item("lamp")
	_dismiss(hud)
	fails += _expect("the door is ready for a key", door.prompt() == "Out to the yard")

	# no key on you: the door says so rather than opening
	door.act()
	_dismiss(hud)
	fails += _expect("no key, no van",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)

	# the card comes off Oyelaran, and it is a card, not the answer
	oyelaran.act()
	_dismiss(hud)
	fails += _expect("he hands over the bay card", Game.has_item("key_card"))
	fails += _expect("which leaves two bays rubbed out",
		Content.ITEMS["key_card"]["body"].contains("rubbed through"))

	# one key off the press at a time
	Game.take_key(0)
	fails += _expect("a key comes off the hook", Game.held_key() == "key_yellow")
	Game.take_key(1)
	fails += _expect("taking another puts the first one back",
		Game.held_key() == "key_green" and not Game.has_item("key_yellow"))

	# wrong tag, right barrel: nothing turns
	fails += _expect("the wrong tag does not turn",
		not Game.try_barrel(Content.VAN_BARREL))
	# right tag, wrong barrel: still nothing
	Game.take_key(2)
	fails += _expect("the bay 2 key is the blue one", Game.held_key() == Content.VAN_KEY)
	fails += _expect("a seized barrel does not turn", not Game.try_barrel(0))
	fails += _expect("nor the middle one", not Game.try_barrel(1))
	fails += _expect("the bottom one does", Game.try_barrel(Content.VAN_BARREL))

	door.act()
	fails += _expect("the lift down starts the drive out", hud.mode == 7)
	fails += _expect("and the world has already moved under it",
		pl.global_position.distance_to(Content.ENTRANCE) < 1.0)
	hud._unhandled_key_input(_key(KEY_E))          # skip the drive
	await _settle(hud)
	fails += _expect("the drive hands you back", hud.mode == 0)

	home.act()
	_dismiss(hud)
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
		hud._title == "Death certificates" and hud._queued.size() == 1)

	_dismiss(hud)
	fails += _expect("the popup names the way out",
		Game.notes[Game.notes.size() - 1].contains("way you came in"))

	home.act()
	fails += _expect("the front door starts the drive back", hud.mode == 7)
	fails += _expect("and puts you back at your desk",
		pl.global_position.distance_to(Content.OFFICE_START) < 1.0)
	hud._unhandled_key_input(_key(KEY_E))
	await _settle(hud)
	fails += _expect("getting back finishes the level", Game.flag("level_done"))
	fails += _expect("and says so", hud.mode == 1 and hud._title == "Level complete")
	fails += _expect("with what you brought in it",
		hud._body.contains("RECOVERED") and hud._body.contains("PAID"))

	print("TRAVEL: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

# Let the drive run itself out.
func _settle(hud) -> void:
	for i in 30:
		if hud.mode != 7:
			return
		await get_tree().process_frame


# Clear the reader and anything waiting behind it.
func _dismiss(hud) -> void:
	for i in 6:
		if hud.mode == 0:
			return
		hud._unhandled_key_input(_key(KEY_E))


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
