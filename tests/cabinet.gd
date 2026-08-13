extends Node2D

# Every cupboard, drawer and unit is its own place something could be hiding,
# so each one rings on its own rather than lighting up the whole run of
# kitchen units it happens to sit in. And you open it by being near it: a
# cupboard must not go out of reach because you walked right up to it.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var pl = get_tree().get_first_node_in_group("player")
	var fails := 0

	var cupboards: Array = []
	for n in get_tree().get_nodes_in_group("act"):
		if is_instance_valid(n) and n.get_script() != null \
				and n.has_method("setup") and n.has_method("highlight") \
				and n.prompt() == "Open":
			cupboards.append(n)

	if cupboards.size() < 4:
		print("FAIL  found only %d cupboards" % cupboards.size())
		fails += 1

	# Two cupboards never share a ring: opening one place to look must not
	# outline the next one along as well.
	var seen := {}
	for c in cupboards:
		var box: Dictionary = c.highlight()
		var key := "%s|%s" % [(box["pos"] as Vector2).round(),
			(box["size"] as Vector2).round()]
		if seen.has(key):
			print("FAIL  the cupboards at %s and %s share one outline %s"
				% [c.position, seen[key], key])
			fails += 1
		seen[key] = c.position
		if OS.get_environment("DUMP") != "":
			print("  %s -> door %s" % [c.position, box["pos"]] + " %s" % box["size"])
		# and a ring the length of a whole worktop is not one cupboard
		if (box["size"] as Vector2).x > 130.0 and (box["size"] as Vector2).y > 130.0:
			print("FAIL  the cupboard at %s outlines a %s slab"
				% [c.position, box["size"]])
			fails += 1

	# Walk in at the front of each one, facing it, and it stays lit the whole
	# way: the ring is not something you lose by getting close. Units stand
	# close enough together that a nearer one can take over, which is right,
	# so only ask for it while it is the nearest one to hand.
	for c in cupboards:
		var box: Dictionary = c.highlight()
		var away: Vector2 = (c.position - (box["pos"] as Vector2))
		if away.length() < 1.0:
			away = Vector2(0, 1)
		away = away.normalized()
		var face: Vector2 = c.reach_point(c.position + away * 40.0)
		var had := false
		var lost := -1
		for gap in range(6, 46, 2):
			var at: Vector2 = face + away * gap
			var mine: float = at.distance_to(c.reach_point(at))
			var nearest := true
			for other in cupboards:
				if other != c and at.distance_to(other.reach_point(at)) < mine:
					nearest = false
			if not nearest:
				continue
			pl.global_position = at
			pl.facing = (-away).angle()
			pl._scan()
			if pl._target == c:
				had = true
			elif had and lost < 0:
				lost = gap
		if not had:
			print("FAIL  the cupboard at %s never lights up on the way in" % c.position)
			fails += 1
		elif lost > 0:
			pl.global_position = face + away * lost
			pl.facing = (-away).angle()
			pl._scan()
			var won: String = pl._target.prompt() if pl._target != null else "nothing"
			print("FAIL  the cupboard at %s goes out %dpx from its face (to %s)"
				% [c.position, lost, won])
			fails += 1

	print("CABINET: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()
