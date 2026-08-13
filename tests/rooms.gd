extends Node2D

# Two rooms are on the house wiring: dark until the switch by the door is
# found, and once lit their light gets out through the doorway and nowhere
# else.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var light = get_tree().get_first_node_in_group("light")
	var fails := 0

	var switches := []
	for n in get_tree().get_nodes_in_group("act"):
		if n.get("room") != null and n.has_method("prompt") \
				and n.prompt().contains("light"):
			switches.append(n)
	fails += _expect("a switch in each wired room", switches.size() == 2)

	# in the bathroom with the light off: your own pool and nothing more
	light._room = 2
	fails += _expect("the bathroom starts dark", not Game.room_lit(2))
	fails += _expect("dark means a pool at your feet", light._carry() == light.GLOW)
	for sw in switches:
		if sw.room == 2:
			sw.act()
	fails += _expect("the switch turns it on", Game.room_lit(2))
	fails += _expect("lit means the run of the room", light._carry() == light.RADIUS)
	for sw in switches:
		if sw.room == 2:
			sw.act()
	fails += _expect("and off again", not Game.room_lit(2))

	# from the bedroom, a lit bathroom shows through the doorway only
	light._room = 3
	var origin := Vector2(990, 300)
	# a ray up through the doorway against one up through the wall beside it
	var through := Vector2(990, 300)      # lined up with the opening
	var beside := Vector2(1150, 300)      # not
	var up := Vector2(0, -1)
	var dark: Array[Rect2] = light._spill(light._lit_rects(through))
	# from the bedroom floor at y=300 the bathroom floor edge is 120px up:
	# reaching it is the wall being lit, passing it is the room being lit
	fails += _expect("an unlit room stops the light at its floor",
		light._wall_limit(through, up, light.RADIUS, dark) <= 121.0)
	Game.room_lights[2] = true
	var lit: Array[Rect2] = light._spill(light._lit_rects(through))
	fails += _expect("a lit room shows through its doorway",
		light._wall_limit(through, up, light.RADIUS, lit) > 150.0)
	fails += _expect("but not through the wall beside the doorway",
		light._wall_limit(beside, up, light.RADIUS, lit) <= 121.0)
	fails += _expect("the room you are in is unaffected",
		light._carry() == light.RADIUS)

	# standing in the frame of a dark room shows you no more of it than
	# standing outside it does
	Game.room_lights[2] = false
	light._room = 3
	var mouth := Vector2(990, 198)          # in the opening itself
	var at_door: Array[Rect2] = light._spill(light._lit_rects(mouth))
	fails += _expect("a dark room stays dark from its own doorway",
		light._wall_limit(mouth, up, light.RADIUS, at_door) < 30.0)
	fails += _expect("and the doorway still has something under it",
		light._which(mouth, at_door) != -1)
	Game.room_lights[2] = true
	var at_door_lit: Array[Rect2] = light._spill(light._lit_rects(mouth))
	fails += _expect("but opens up once it is lit",
		light._wall_limit(mouth, up, light.RADIUS, at_door_lit) > 80.0)

	print("ROOMS: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
