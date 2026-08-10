extends Node2D

# Every interactable must have somewhere you can actually stand that is within
# the player's reach of it. A thing you can walk to but never prompt on is a
# dead end.

const PR := 14.0
const CELL := 6.0
const REACH := 34.0   # must match player.gd
const OPEN := 62.0    # must match Container2D.OPEN_REACH

var FP
var _walls: Array[Rect2] = []

func _ready() -> void:
	FP = load("res://scripts/floorplan.gd")
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

	var fails := 0
	# Hardened limbs gate each other: dissolving the one across a doorway is
	# what puts you within reach of the ones behind it. Work outwards from
	# what is in reach now, the way play does, and every one of them has to
	# come up at some point — a limb no round can reach is a dead end.
	var gone := {}
	var moved := true
	while moved:
		moved = false
		var reach := _flood(gone, [0, 1])
		for i in Content.BRANCHES.size():
			if not Content.BRANCHES[i]["strong"] or gone.has(i):
				continue
			if _nearest_limb(reach, Content.BRANCHES[i]) <= REACH:
				gone[i] = true
				moved = true
	for i in Content.BRANCHES.size():
		var b: Dictionary = Content.BRANCHES[i]
		if not b["strong"]:
			continue
		if gone.has(i):
			print("ok   strong limb %d at %s" % [i, b["pos"]])
		else:
			print("FAIL strong limb %d at %s is never within reach" % [i, b["pos"]])
			fails += 1

	# With the limbs gone, every container must be promptable too.
	var open_reach := _flood(_all_strong(), [0, 1])
	for i in Content.CONTAINERS.size():
		var d := _nearest(open_reach, Content.CONTAINERS[i]["pos"])
		if d > OPEN:
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


# Every hardened limb, as the "all of them dissolved" state.
func _all_strong() -> Dictionary:
	var all := {}
	for i in Content.BRANCHES.size():
		if Content.BRANCHES[i]["strong"]:
			all[i] = true
	return all


# `gone` holds the indices of hardened limbs already dissolved; the rest of
# them still block.
func _flood(gone: Dictionary, cleared: Array) -> Dictionary:
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
			if _blocked(w, gone, cleared):
				continue
			seen[n] = true
			q.append(n)
	return seen


func _blocked(p: Vector2, gone: Dictionary, cleared: Array) -> bool:
	for r in _walls:
		if r.grow(PR).has_point(p):
			return true
	for i in Content.BRANCHES.size():
		var b: Dictionary = Content.BRANCHES[i]
		if not b["strong"] or gone.has(i):
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
