extends Node2D

# You have to be turned towards a thing to work on it, with one exception:
# something you are all but standing on is always in reach.

# A limb out in the middle of the living room, clear of anything else that
# answers to E — the barricade by the front door has the way home beside it.
const LIMB := Vector2(1180, 660)


func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var pl = get_tree().get_first_node_in_group("player")
	var fails := 0

	var limb = null
	for n in get_tree().get_nodes_in_group("act"):
		if n.has_method("cuttable") and n.global_position.is_equal_approx(LIMB):
			limb = n
	fails += _expect("found the barricade limb", limb != null)

	# Standing beside it, out of touching range but well inside reach.
	pl.global_position = LIMB + Vector2(33, 0)
	pl.facing = PI                            # looking west, at the limb
	pl._scan()
	fails += _expect("turned towards the limb, it is the target", pl._target == limb)

	pl.facing = 0.0                           # looking east, away from it
	pl._scan()
	fails += _expect("turned away, nothing is targeted", pl._target == null)

	pl.facing = PI / 2.0                      # side on, outside the cone
	pl._scan()
	fails += _expect("side on, nothing is targeted", pl._target == null)

	# Out of range altogether, however you are turned.
	pl.global_position = LIMB + Vector2(90, 0)
	pl.facing = PI
	pl._scan()
	fails += _expect("too far to reach", pl._target == null)

	# An item under your feet does not care which way you last walked.
	var item: Vector2 = Content.ITEMS["extinguisher"]["pos"]
	pl.global_position = item
	pl.facing = PI / 2.0
	pl._scan()
	fails += _expect("picked up what you are stood on", pl._target != null
		and pl._target.get("id") == "extinguisher")

	print("FACING: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()


func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
