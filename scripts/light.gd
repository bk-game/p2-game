extends Node2D

# The investigator carries a lantern, so the lit area is a circle around them.
# It stops at the walls of the room they are in rather than shining through
# them. [C] toggles it.

const SEGMENTS := 256
const RADIUS   := 330.0                 # how far the lantern carries
const FAR      := 3000.0
const PAD      := 26.0                  # bleed past the room so walls read

# Successively smaller circles layered on top of each other make a soft edge.
const PASSES := [
	{"k": 1.00, "a": 0.97},
	{"k": 0.86, "a": 0.42},
	{"k": 0.70, "a": 0.24},
]

const ROOMS := [
	[Rect2(102, 94, 173, 321)],                                  # hidden shed
	[Rect2(312, 94, 578, 506)],                                  # kitchen / dining
	[Rect2(927, 94, 343, 86)],                                   # bathroom
	[Rect2(927, 217, 486, 361)],                                 # bedroom
	[Rect2(102, 452, 173, 526), Rect2(275, 637, 175, 341)],      # utility
	[Rect2(487, 615, 1126, 363)],                                # living room
	[Rect2(1380, 978, 180, 260)],                                # front step
]

var enabled := true
var _player: Node2D = null
var _room := 5


func _ready() -> void:
	add_to_group("light")
	global_position = Vector2.ZERO


func toggle() -> void:
	enabled = not enabled
	queue_redraw()
	Game.toast.emit("Lantern %s." % ("on" if enabled else "off"))


func _process(_d: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	_room = _room_at(_player.global_position)
	if enabled:
		queue_redraw()


func _room_at(p: Vector2) -> int:
	for i in ROOMS.size():
		for rect in ROOMS[i]:
			if (rect as Rect2).has_point(p):
				return i
	return _room   # keep the last room while standing in a doorway


func _draw() -> void:
	if not enabled or _player == null:
		return
	var origin: Vector2 = _player.global_position
	var lit: Array[Rect2] = []
	for rect in ROOMS[_room]:
		lit.append((rect as Rect2).grow(PAD))

	# How far the light gets along each ray: full radius, cut short by walls.
	var reach := PackedFloat32Array()
	reach.resize(SEGMENTS)
	for i in SEGMENTS:
		var a := TAU * i / SEGMENTS
		reach[i] = _wall_limit(origin, Vector2(cos(a), sin(a)), RADIUS, lit)

	for step in PASSES:
		_shroud(origin, reach, step["k"], Color(0.012, 0.016, 0.022, step["a"]))


# Where the ray leaves the room. Solved exactly against the rectangle edges,
# so the lit area ends flush along a wall instead of in 8px stair-steps.
func _wall_limit(origin: Vector2, dir: Vector2, want: float,
		lit: Array[Rect2]) -> float:
	if _which(origin, lit) == -1:
		return want          # caught in a doorway: do not black everything out
	var t := 0.0
	for _hop in 4:           # step across at most a few abutting rectangles
		var i := _which(origin + dir * (t + 0.5), lit)
		if i == -1:
			return minf(t, want)
		var e := _exit(origin, dir, lit[i])
		if e <= t:
			return minf(t, want)
		t = e
		if t >= want:
			return want
	return minf(t, want)


func _which(p: Vector2, lit: Array[Rect2]) -> int:
	for i in lit.size():
		if lit[i].has_point(p):
			return i
	return -1


# Distance at which the ray exits this rectangle.
func _exit(o: Vector2, d: Vector2, r: Rect2) -> float:
	var tx := INF
	if absf(d.x) > 1e-6:
		tx = maxf((r.position.x - o.x) / d.x, (r.end.x - o.x) / d.x)
	var ty := INF
	if absf(d.y) > 1e-6:
		ty = maxf((r.position.y - o.y) / d.y, (r.end.y - o.y) / d.y)
	return minf(tx, ty)


# Fill everything beyond the beam with darkness, as a fan of quads.
func _shroud(origin: Vector2, reach: PackedFloat32Array, k: float,
		col: Color) -> void:
	for i in SEGMENTS:
		var j := (i + 1) % SEGMENTS
		var a0 := TAU * i / SEGMENTS
		var a1 := TAU * (i + 1) / SEGMENTS
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		draw_colored_polygon(PackedVector2Array([
			origin + d0 * reach[i] * k,
			origin + d1 * reach[j] * k,
			origin + d1 * FAR,
			origin + d0 * FAR]), col)
