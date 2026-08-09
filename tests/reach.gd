extends Node2D

# Flood-fills the walkable floor at each stage of the puzzle and asserts the
# things you need next are actually reachable. Catches soft-locks.

const PR := 14.0   # player radius
const CELL := 6.0
const REACH := 34.0   # must match player.gd

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
	# stage: which branch strengths are passable, which fumes are cleared
	# every measure of the formula has to be readable before you can mix, so
	# all three pieces belong in the first stage
	fails += _stage("A start (bare hands)", false, [], [
		"extinguisher", "log_1_2", "log_3", "log_5_6", "log_formula", "log_water",
		"log_dregs", "<wall>", "norust", "bleach", "exfluid", "water",
		"police_report", "card_christopher", "card_eleanor"])
	fails += _stage("B extinguisher clears the utility fume", false, [1], [
		"<sink>", "letter_doctor"])
	fails += _stage("C solution breaks strong limbs", true, [1], [
		"axe", "family_photos", "death_certs", "marriage_photo"])
	fails += _stage("D extinguisher clears the rest of the air", true, [0, 1],
		["<body>"])

	if OS.get_environment("DUMP") != "":
		_dump(_flood(false, [1]))
	print("REACH: %s" % ("ALL PASS" if fails == 0 else "%d UNREACHABLE" % fails))
	get_tree().quit()


func _stage(label: String, strong_ok: bool, cleared: Array, targets: Array) -> int:
	var reach := _flood(strong_ok, cleared)
	var bad := 0
	for t in targets:
		var p: Vector2 = Content.SINK if t == "<sink>" else \
			(Content.BODY_POS if t == "<body>" else \
			(Content.FIXED_NOTES[0]["pos"] if t == "<wall>" else Content.ITEMS[t]["pos"]))
		if not _near(reach, p):
			print("FAIL  [%s] cannot reach %s at %s" % [label, t, p])
			bad += 1
	return bad


# A target counts as reachable if open floor exists within arm's length of it.
func _near(reach: Dictionary, p: Vector2) -> bool:
	for c in reach:
		if (Vector2(c.x, c.y) * CELL).distance_to(p) < REACH:
			return true
	return false


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
		if b["strong"] and strong_ok:
			continue      # dissolved with the solution
		if not b["strong"]:
			continue      # cut by hand
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


# Coarse map of the reachable floor, for diagnosing where a route is cut.
func _dump(reach: Dictionary) -> void:
	var step := 4
	for gy in range(6, 175, step):
		var row := ""
		for gx in range(6, 282, step):
			row += "#" if reach.has(Vector2i(gx, gy)) else "."
		print(row)
