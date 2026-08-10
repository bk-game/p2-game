extends Node2D

# The bathroom door is shut until the dial is given Christopher's birthday,
# and the door is as solid as the wall until then.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	var lock = null
	for n in get_tree().get_nodes_in_group("act"):
		if n.has_method("prompt") and n.prompt() == "Locked — a four-digit dial":
			lock = n
	fails += _expect("the door has a lock on it", lock != null)
	fails += _expect("and something holding it shut",
		lock != null and is_instance_valid(lock.bolt))

	var bolt = lock.bolt   # the lock frees itself once open, the bolt with it
	lock.act()
	fails += _expect("the dial opens on E", hud.mode == 5)
	for k in [KEY_1, KEY_2, KEY_3, KEY_4]:
		hud._lock_key(k)
	hud._lock_key(KEY_ENTER)
	fails += _expect("a wrong code does nothing", not Game.flag("bedroom_open"))
	fails += _expect("and clears itself to try again", hud._code == "")
	fails += _expect("the door is still shut", is_instance_valid(bolt))

	for k in [KEY_1, KEY_5, KEY_1, KEY_0]:
		hud._lock_key(k)
	hud._lock_key(KEY_ENTER)
	await get_tree().process_frame
	fails += _expect("Christopher's birthday opens it", Game.flag("bedroom_open"))
	fails += _expect("back to walking around", hud.mode == 0)
	fails += _expect("and the doorway is clear now", not is_instance_valid(bolt))
	fails += _expect("the dial goes with it", not is_instance_valid(lock))

	print("LOCK: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0
