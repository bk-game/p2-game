extends Node2D

# Every interactable must be selectable: there has to be somewhere you can
# stand where pressing E actually targets it. Geometric proximity is not
# enough — a nearer object can mask it, and a long object's origin can sit
# further away than the player can ever reach.

const PR := 14.0
const CELL := 6.0

var _walls: Array[Rect2] = []
var _pl: Node2D
var _fails := 0


func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	_pl = get_tree().get_first_node_in_group("player")
	Game.solution_charges = 3
	Game.inventory.append("extinguisher")

	var FP = load("res://scripts/floorplan.gd")
	for w in FP.WALLS:
		var parts: Array = [w]
		for d in FP.DOORS:
			if d.get("shut", false):
				continue      # never walked through, so it is still wall
			var nxt: Array = []
			for p in parts:
				nxt.append_array(_sub(p, d["rect"]))
			parts = nxt
		for p in parts:
			_walls.append(p)
	for s in FP.SOLIDS:
		_walls.append(s)

	# Hardened limbs gate each other, so which ones are standing depends on
	# how far in you are; tests/interact covers that chain. Here the question
	# is only whether a limb can be picked out from where you stand, so probe
	# from open floor.
	var for_strong := _flood(true, [0, 1])   # limbs cleared, air clear
	var for_fumes := _flood(true, [])            # clouds still there
	var for_rest := _flood(true, [0, 1])      # everything opened up

	for n in get_tree().get_nodes_in_group("act"):
		if not is_instance_valid(n):
			continue
		var fill := for_rest
		var kind := "thing"
		if n is StaticBody2D:
			kind = "limb"
			if n.strong:
				fill = for_strong
		elif n.get("radius") != null:
			kind = "fume"
			fill = for_fumes
		_check(n, fill, kind)

	print("PROMPT: %s" % ("ALL PASS" if _fails == 0 else "%d NOT SELECTABLE" % _fails))
	get_tree().quit()


# Probing scenery: pickups are consumed in play, so hide them first. Anything
# still masked is masked by something permanent, which is a real dead end.
func _check(n: Node2D, fill: Dictionary, kind: String) -> void:
	var hidden: Array = []
	if kind != "thing":
		for o in get_tree().get_nodes_in_group("act"):
			if o != n and o.has_method("bias") and o.bias() >= 45.0:
				o.remove_from_group("act")
				hidden.append(o)
	var spots: Array[Vector2] = []
	for c in fill:
		var w := Vector2(c.x, c.y) * CELL
		if w.distance_to(n.global_position) < 190.0:
			spots.append(w)
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_to(n.global_position) < b.distance_to(n.global_position))
	for i in mini(spots.size(), 80):
		_pl.global_position = spots[i]
		# You have to be turned towards a thing to target it, and walking up
		# to it is what turns you: face the point you would be touching.
		var at: Vector2 = n.reach_point(spots[i]) if n.has_method("reach_point") \
			else n.global_position
		if spots[i].distance_to(at) > 0.01:
			_pl.facing = (at - spots[i]).angle()
		_pl._scan()
		if _pl._target == n:
			for o in hidden:
				o.add_to_group("act")
			return
	for o in hidden:
		o.add_to_group("act")
	_fails += 1
	print("FAIL  %s at %s is never the E target (%d standing spots tried)"
		% [kind, n.global_position, mini(spots.size(), 80)])


func _flood(strong_ok: bool, cleared: Array) -> Dictionary:
	# two places, no path between them: seed the flood in both
	var seen := {}
	var q: Array[Vector2i] = []
	for at in [Content.ENTRANCE, Content.OFFICE_START]:
		var start := Vector2i(at / CELL)
		seen[start] = true
		q.append(start)
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			var w := Vector2(n.x, n.y) * CELL
			if w.x < -900 or w.x > 1680 or w.y < 40 or w.y > 1240:
				continue
			if _blocked(w, strong_ok, cleared):
				continue
			seen[n] = true
			q.append(n)
	return seen


func _blocked(p: Vector2, strong_ok: bool, cleared: Array) -> bool:
	for r in _walls:
		if r.grow(PR).has_point(p):
			return true
	for b in Content.BRANCHES:
		if not b["strong"] or strong_ok:
			continue
		var l: Vector2 = (p - b["pos"]).rotated(-deg_to_rad(b["deg"]))
		if abs(l.x) <= b["len"] * 0.5 + PR and abs(l.y) <= b["thick"] * 0.5 + PR:
			return true
	for i in Content.FUMES.size():
		if cleared.has(i):
			continue
		if p.distance_to(Content.FUMES[i]["pos"]) < Content.FUMES[i]["r"] * 0.72 + PR:
			return true
	return false


func _sub(a: Rect2, b: Rect2) -> Array:
	if not a.intersects(b):
		return [a]
	var i := a.intersection(b)
	var out := []
	if a.size.x >= a.size.y:
		if i.position.x - a.position.x > 0.5:
			out.append(Rect2(a.position, Vector2(i.position.x - a.position.x, a.size.y)))
		if a.end.x - i.end.x > 0.5:
			out.append(Rect2(Vector2(i.end.x, a.position.y), Vector2(a.end.x - i.end.x, a.size.y)))
	else:
		if i.position.y - a.position.y > 0.5:
			out.append(Rect2(a.position, Vector2(a.size.x, i.position.y - a.position.y)))
		if a.end.y - i.end.y > 0.5:
			out.append(Rect2(Vector2(a.position.x, i.end.y), Vector2(a.size.x, a.end.y - i.end.y)))
	return out
