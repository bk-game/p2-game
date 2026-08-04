extends Node2D

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var fails := 0

	var limbs := []
	for n in get_tree().get_nodes_in_group("act"):
		if n.has_method("cuttable"):
			limbs.append(n)
	fails += _expect("limbs exist", limbs.size() == Content.BRANCHES.size())

	# a pale limb: five seconds of sawing, not one tap
	var weak = null
	var strong = null
	for n in limbs:
		if not n.strong and weak == null:
			weak = n
		if n.strong and strong == null:
			strong = n

	weak.act()
	fails += _expect("tapping E does not fell a limb", is_instance_valid(weak))
	for i in 49:
		weak.saw(0.1)
	fails += _expect("still standing at 4.9s", is_instance_valid(weak))
	fails += _expect("cracks are showing", weak.cut > 4.8)
	weak.saw(0.2)
	await get_tree().process_frame
	fails += _expect("felled at 5s", not is_instance_valid(weak))

	# letting go closes the cut back up
	var other = null
	for n in limbs:
		if is_instance_valid(n) and not n.strong:
			other = n
			break
	for i in 20:
		other.saw(0.1)
	var peak: float = other.cut
	for i in 40:
		other.relax(0.1)
	fails += _expect("cut relaxes when released", other.cut < peak)
	fails += _expect("relax stops at zero", other.cut >= 0.0)

	# hardened limbs cannot be sawn at all until treated
	fails += _expect("hardened limb is not cuttable", not strong.cuttable())
	fails += _expect("sawing a hardened limb does nothing", strong.saw(1.0) == 0.0)
	Game.solution_charges = 1
	strong.act()
	fails += _expect("solution makes it brittle", strong.brittle)
	fails += _expect("brittle limb is cuttable", strong.cuttable())
	fails += _expect("dose consumed", Game.solution_charges == 0)

	print("CUT: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
