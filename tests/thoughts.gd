extends Node2D

# The things you say to yourself: the right line for what you know and what
# you are carrying, each one only once.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	Game.think("arrive")
	fails += _expect("arriving says something", hud._thought.contains("forest"))

	# the same trigger gives the next line, not the same one twice
	Game.think("tree")
	var first: String = hud._thought
	Game.think("tree")
	fails += _expect("a second look says something else", hud._thought != first)
	Game.think("tree")
	fails += _expect("and then it has nothing left to say", hud._thought != "")

	# what you know changes what you say about the same bottle
	hud._thought = ""
	Game.think("exfluid")
	fails += _expect("not knowing the recipe reads as a guess",
		hud._thought.contains("not really sure"))
	Game.set_flag("knows_formula")
	hud._thought = ""
	Game.think("exfluid")
	fails += _expect("knowing it reads as relief", hud._thought.contains("needed this"))

	# and what you are carrying does too
	hud._thought = ""
	Game.think("bunny")
	fails += _expect("the rabbit is a question first",
		hud._thought.contains("Who is Eleanor"))
	Game.inventory.append("death_certs")
	hud._thought = ""
	Game.think("bunny")
	fails += _expect("and an answer once you have the certificates",
		hud._thought.contains("share of loss"))

	# picking a thing up is enough on its own
	hud._thought = ""
	Game.add_item("norust")
	fails += _expect("picking up the no-rust says something", hud._thought != "")

	print("THOUGHTS: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
