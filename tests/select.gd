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
				# turned towards the thing itself: for a unit that is its
				# nearest edge, not the patch of floor it stands on
				var at: Vector2 = n.reach_point(pl.global_position) \
					if n.has_method("reach_point") else n.global_position
				var look: Vector2 = at - pl.global_position
				pl.facing = look.angle() if look.length() > 0.01 else (-dir).angle()
				pl._scan()
				if pl._target == n:
					had = true
				elif had and lost < 0:
					# Units stand close enough together to share a doorstep, so
					# one handing over to a nearer unit is not losing it. Losing
					# it to something further off is the bug this suite is for.
					var t = pl._target
					var handoff: bool = t != null and n.has_method("must_face") \
						and t.has_method("must_face") \
						and pl.global_position.distance_to(
							t.reach_point(pl.global_position)) \
							< pl.global_position.distance_to(at)
					if not handoff:
						lost = d
			if had and lost > 0 and lost < 30 and OS.get_environment("DUMP") != "":
				pl.global_position = n.global_position + dir * lost
				var at2: Vector2 = n.reach_point(pl.global_position) \
					if n.has_method("reach_point") else n.global_position
				pl.facing = (at2 - pl.global_position).angle()
				pl._scan()
				print("  at %s -> %s at %s" % [pl.global_position,
					pl._target.prompt() if pl._target != null else "nothing",
					pl._target.global_position if pl._target != null else Vector2.ZERO])
			if had and lost > 0 and lost < 30:
				print("FAIL  %s at %s stops being the target %dpx away, walking in "
					% [n.prompt(), n.global_position, lost]
					+ "from %s" % dir)
				fails += 1

	print("SELECT: %s" % ("ALL PASS" if fails == 0 else "%d LOST ON APPROACH" % fails))
	get_tree().quit()
