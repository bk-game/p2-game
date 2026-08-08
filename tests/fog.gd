extends Node2D

# Standing in a cloud gives you a couple of seconds to get out of it before
# it puts you back on the doorstep, and the green builds and clears with you.

const CLEAR := Vector2(1462, 935)   # the doorstep, well away from any cloud


func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var pl = get_tree().get_first_node_in_group("player")
	var cloud: Vector2 = Content.FUMES[0]["pos"]
	var fails := 0

	# in it, but not for long enough yet
	pl.global_position = cloud
	await _hold(pl, cloud, 0.7)
	fails += _expect("standing in it starts the clock", Game.fog > 0.3)
	fails += _expect("green builds up, does not snap on", Game.fog < Game.FOG_LIMIT)
	fails += _expect("still on your feet after most of a second",
		pl.global_position.distance_to(cloud) < 1.0)

	# get out and it washes off
	pl.global_position = CLEAR
	await get_tree().create_timer(1.4).timeout
	fails += _expect("leaving clears the green", Game.fog <= 0.0)
	fails += _expect("leaving in time costs you nothing",
		pl.global_position.distance_to(CLEAR) < 1.0)

	# stay in it and you come to on the doorstep
	pl.global_position = cloud
	await _hold(pl, cloud, Game.FOG_LIMIT + 0.5)
	fails += _expect("staying past the limit puts you at the door",
		pl.global_position.distance_to(Content.ENTRANCE) < 1.0)
	fails += _expect("and the green goes with it", Game.fog <= 0.0)

	print("FOG: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()


# Hold the player in the cloud for a while. Movement is the player's own, so
# nothing else pushes them; this only stops the test drifting.
func _hold(pl: Node2D, at: Vector2, secs: float) -> void:
	var t := 0.0
	while t < secs:
		if pl.global_position.distance_to(Content.ENTRANCE) > 1.0:
			pl.global_position = at
		t += get_process_delta_time()
		await get_tree().process_frame


func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
