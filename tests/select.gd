extends Node2D

# Walking towards a thing must not lose it. A limb is metres long, so it
# reports no distance from anywhere along it and used to win every contest
# on proximity: walk up to a cupboard standing among the roots and the
# cupboard would go out of reach as you got closer to it.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var pl = get_tree().get_first_node_in_group("player")
	Game.set_flag("read_job")
	var fails := 0

	for n in get_tree().get_nodes_in_group("act"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if n.has_method("cuttable"):
			continue        # limbs overlap each other; the ring shows which
		for dir in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
			var had := false
			var lost := -1
			for d in range(4, 70, 2):
				pl.global_position = n.global_position + dir * d
				pl.facing = (-dir).angle()
				pl._scan()
				if pl._target == n:
					had = true
				elif had and lost < 0:
					lost = d
			if had and lost > 0 and lost < 30:
				print("FAIL  %s at %s stops being the target %dpx away, walking in "
					% [n.prompt(), n.global_position, lost]
					+ "from %s" % dir)
				fails += 1

	print("SELECT: %s" % ("ALL PASS" if fails == 0 else "%d LOST ON APPROACH" % fails))
	get_tree().quit()
