extends Node2D

# Every interactable must have somewhere you can actually stand that is within
# the player's reach of it. A thing you can walk to but never prompt on is a
# dead end.

const PR := 14.0
const CELL := 6.0
const REACH := 48.0   # must match player.gd

var FP
var _walls: Array[Rect2] = []

func _ready() -> void:
	FP = load("res://scripts/floorplan.gd")
	for w in FP.WALLS:
		var parts: Array = [w]
		for d in FP.DOORS:
			var nxt: Array = []
			for p in parts:
				nxt.append_array(_sub(p, d["rect"]))
			parts = nxt
		for p in parts:
			_walls.append(p)
	for s in FP.SOLIDS:
		_walls.append(s)

	var fails := 0
	# Fumes all cleared, strong limbs still standing: you must be able to
	# prompt on every strong limb in order to dissolve it.
	var reach := _flood(false, [0, 1, 2])
	for i in Content.BRANCHES.size():
		var b: Dictionary = Content.BRANCHES[i]
		if not b["strong"]:
			continue
		var d := _nearest_limb(reach, b)
		var ok := d <= REACH
		print("%s strong limb %d at %s — closest you can stand: %.0f px (reach %d)"
			% ["ok  " if ok else "FAIL", i, b["pos"], d, REACH])
		if not ok:
			fails += 1

	# With the limbs gone, every container must be promptable too.
	var open_reach := _flood(true, [0, 1, 2])
	for i in Content.CONTAINERS.size():
		var d := _nearest(open_reach, Content.CONTAINERS[i]["pos"])
		if d > REACH:
			print("FAIL container %d at %s — closest %.0f px"
				% [i, Content.CONTAINERS[i]["pos"], d])
			fails += 1
	var d_body := _nearest(open_reach, Content.BODY_POS)
	if d_body > REACH:
		print("FAIL body at %s — closest %.0f px" % [Content.BODY_POS, d_body])
		fails += 1

	print("INTERACT: %s" % ("ALL PASS" if fails == 0 else "%d UNREACHABLE" % fails))
	get_tree().quit()


# A limb prompts from its nearest point, not its midpoint — measure it the
# same way Branch.reach_point does, or a long limb reads as out of range.
func _nearest_limb(reach: Dictionary, b: Dictionary) -> float:
	var rot: float = deg_to_rad(b["deg"])
	var best := 1e9
	for c in reach:
		var p: Vector2 = Vector2(c.x, c.y) * CELL
		var l: Vector2 = (p - b["pos"]).rotated(-rot)
		l.x = clampf(l.x, -b["len"] * 0.5, b["len"] * 0.5)
		l.y = clampf(l.y, -b["thick"] * 0.5, b["thick"] * 0.5)
		var on: Vector2 = b["pos"] + l.rotated(rot)
		var d := p.distance_to(on)
		if d < best:
			best = d
	return best


func _nearest(reach: Dictionary, target: Vector2) -> float:
	var best := 1e9
	for c in reach:
		var d: float = (Vector2(c.x, c.y) * CELL).distance_to(target)
		if d < best:
			best = d
	return best


func _flood(strong_ok: bool, cleared: Array) -> Dictionary:
	var seen := {}
	var start := Vector2i(Content.ENTRANCE / CELL)
	var q: Array[Vector2i] = [start]
	seen[start] = true
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			var w := Vector2(n.x, n.y) * CELL
			if w.x < 40 or w.x > 1680 or w.y < 40 or w.y > 1040:
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
