extends Node2D

# The limb grown into the doorframe takes both things: a dose of the
# solution to soften it, and the three cuts taken in the order the grain
# gives. Either on its own leaves it standing.

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
	for k in [KEY_3, KEY_2, KEY_1]:
		hud._cut_key(k)
	hud._cut_key(KEY_ENTER)
	fails += _expect("a wrong order binds", not Game.flag("gate_cut"))
	fails += _expect("still standing", not gate.cuttable())

	for k in [KEY_2, KEY_3, KEY_1]:
		hud._cut_key(k)
	hud._cut_key(KEY_ENTER)
	fails += _expect("knot, split, ring gives", Game.flag("gate_cut"))
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
