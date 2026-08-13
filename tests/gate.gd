extends Node2D

# The limb grown into the doorframe takes both things: a dose of the
# solution to soften it, and the four cuts taken in the order the grain
# gives. Either on its own leaves it standing. Guessing is not a way through
# it either: a wrong order leaves the blade stuck in the limb, and it takes
# real seconds of holding E to get it back out before the next try.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	var gate = null
	for n in get_tree().get_nodes_in_group("act"):
		if n.has_method("cuttable") and n.get("gate"):
			gate = n
	fails += _expect("the doorframe limb is marked as one", gate != null)
	fails += _expect("hardened to start with", not gate.cuttable())

	Game.solution_charges = 1
	gate.act()
	fails += _expect("a dose softens it", gate.brittle)
	fails += _expect("softened is not enough", not gate.cuttable())
	fails += _expect("and it says so", gate.prompt().contains("bind"))
	fails += _expect("sawing it does nothing", gate.saw(1.0) == 0.0)

	gate.act()
	fails += _expect("E opens the grain instead", hud.mode == 6)
	for k in [KEY_1, KEY_2, KEY_3]:
		hud._cut_key(k)
	hud._cut_key(KEY_ENTER)
	fails += _expect("three of the four is not an answer", hud.mode == 6)
	for k in [KEY_4]:
		hud._cut_key(k)
	hud._cut_key(KEY_ENTER)
	fails += _expect("a wrong order binds", not Game.flag("gate_cut"))
	fails += _expect("still standing", not gate.cuttable())

	# the cost of a guess: the blade is in the limb and the panel is shut
	fails += _expect("the panel closes on a wrong order", hud.mode == 0)
	fails += _expect("the blade is stuck", Game.cut_bound)
	fails += _expect("and it says so", gate.prompt().contains("stuck"))
	gate.act()
	fails += _expect("E will not open the grain again", hud.mode == 0)
	for i in 10:
		gate.saw(0.1)
	fails += _expect("a second of pulling is not enough", Game.cut_bound)
	gate.relax(1.0)
	for i in 10:
		gate.saw(0.1)
	fails += _expect("letting go loses the ground you made", Game.cut_bound)
	for i in 25:
		gate.saw(0.1)
	fails += _expect("three seconds gets the blade out", not Game.cut_bound)
	fails += _expect("and it does not fell the limb", is_instance_valid(gate))

	# and it goes in deeper every time, so guessing gets dearer as you go
	gate.act()
	for k in [KEY_2, KEY_1, KEY_3, KEY_4]:
		hud._cut_key(k)
	hud._cut_key(KEY_ENTER)
	fails += _expect("a second guess binds it again", Game.cut_bound)
	for i in 31:
		gate.saw(0.1)
	fails += _expect("three seconds no longer gets it out", Game.cut_bound)
	for i in 20:
		gate.saw(0.1)
	fails += _expect("but five does", not Game.cut_bound)

	gate.act()
	fails += _expect("now the grain opens again", hud.mode == 6)
	for k in [KEY_3, KEY_4, KEY_2, KEY_1]:
		hud._cut_key(k)
	hud._cut_key(KEY_ENTER)
	fails += _expect("knot, split, seam, ring gives", Game.flag("gate_cut"))
	fails += _expect("and now it can be cut", gate.cuttable())
	fails += _expect("back to walking around", hud.mode == 0)
	for i in 25:
		if is_instance_valid(gate):
			gate.saw(0.1)
	await get_tree().process_frame
	fails += _expect("and sawing fells it", not is_instance_valid(gate))

	print("GATE: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
