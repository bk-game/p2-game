extends Node2D

# What you can see. Most rooms are lit and the lit area is a circle around
# you, stopping at the walls of the room you are in rather than shining
# through them. Two rooms are on the house wiring and are dark until their
# switch is found: in those you see only as far as your own light reaches,
# and once they are lit their light gets out through the doorway. [C] toggles
# the whole thing.

const SEGMENTS := 256
const RADIUS   := 330.0                 # how far the lantern carries
const FAR      := 3000.0
const PAD      := 26.0                  # bleed past the room so walls read
const STRANDED := 70.0                  # all the light you get somewhere unmapped
const GLOW     := 78.0                  # what you can see by yourself, unlit

# Rooms on the house wiring: pitch dark until their switch is found.
# Everywhere else is lit as it always was.
const SWITCHED := [2, 0]                 # bathroom, the room at the back

# The openings, taken from the plan so there is one copy of where they are.
const PLAN := preload("res://scripts/floorplan.gd")

var _doorways: Array[Rect2] = []

# The dark closes in over the outer part of the beam as a gradient rather
# than in steps: rings of vertex-coloured quads carry the alpha from clear
# at K_IN up to A_MAX where the beam runs out, sampling a smoothstep so
# neither end of the falloff shows an edge.
const DARK   := Color(0.012, 0.016, 0.022)
const K_IN   := 0.55    # fraction of the reach where the falloff starts
const A_MAX  := 0.985   # opacity beyond the beam
const BANDS  := 5

const ROOMS := [
	[Rect2(102, 94, 173, 321)],                                  # hidden shed
	[Rect2(312, 94, 578, 506)],                                  # kitchen / dining
	[Rect2(927, 94, 343, 86)],                                   # bathroom
	[Rect2(927, 217, 486, 361)],                                 # bedroom
	[Rect2(102, 452, 173, 526), Rect2(275, 637, 175, 341)],      # utility
	[Rect2(487, 615, 1126, 363)],                                # living room
	[Rect2(1380, 978, 180, 260)],                                # front step
	[Rect2(-783, 157, 212, 181)],                                # lift, upstairs
	[Rect2(-783, 368, 212, 181)],                                # store cupboard
	[Rect2(-549, 157, 289, 392)],                                # the office
]

var enabled := true
var _player: Node2D = null
var _room := 9        # the office, where the day starts


func _ready() -> void:
	add_to_group("light")
	global_position = Vector2.ZERO
	for d in PLAN.DOORS:
		_doorways.append(d["rect"] as Rect2)


func _dark(room: int) -> bool:
	return SWITCHED.has(room) and not Game.room_lit(room)


# The openings into a room, for carrying its light out or your own in.
func _mouths(room: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d in _doorways:
		for rect in ROOMS[room]:
			if (rect as Rect2).grow(2.0).intersects(d):
				out.append(d)
	return out


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


func _room_exact(p: Vector2) -> int:
	for i in ROOMS.size():
		for rect in ROOMS[i]:
			if (rect as Rect2).has_point(p):
				return i
	return -1


func _room_at(p: Vector2) -> int:
	var i := _room_exact(p)
	return i if i != -1 else _room   # keep the last room in a doorway


# The rooms the lantern fills. A doorway is thicker than the bleed, so for a
# few pixels in the middle of one you are past the padded edge of the room
# you came from and not yet inside the next: the beam then finds no wall to
# stop at and lights the whole house through them. Standing in a doorway,
# take every room the bleed reaches from here — you are in both at once.
func _lit_rects(origin: Vector2) -> Array[Rect2]:
	var lit: Array[Rect2] = []
	for rect in ROOMS[_room]:
		lit.append((rect as Rect2).grow(PAD))
	if _room_exact(origin) != -1:
		return lit                     # standing in a room proper
	# In a doorway: the opening itself carries the light across the gap, so
	# there is always something under you. The room on the far side comes in
	# only if it is lit — standing in the frame of a dark room should show
	# you no more of it than standing outside it does.
	for d in _doorways:
		if d.has_point(origin):
			lit.append(d)
	for i in ROOMS.size():
		if i == _room or _dark(i):
			continue
		for rect in ROOMS[i]:
			var g: Rect2 = (rect as Rect2).grow(PAD)
			if g.has_point(origin):
				lit.append(g)
	return lit


# A room with its light on is visible from outside it, but only through its
# doorway: its floor goes in unpadded and its doorway bridges the gap to the
# room you are in, so a ray can walk through the opening and no further. The
# wall either side has nothing under it and stops the ray dead.
func _spill(lit: Array[Rect2]) -> Array[Rect2]:
	for i in SWITCHED:
		if i == _room or _dark(i):
			continue
		for rect in ROOMS[i]:
			lit.append(rect as Rect2)
		lit.append_array(_mouths(i))
	return lit


# How far the lantern carries from here. Your own light is a pool at your
# feet; the run of a room is only yours if the room is lit.
func _carry() -> float:
	return GLOW if _dark(_room) else RADIUS


func _draw() -> void:
	if not enabled or _player == null:
		return
	var origin: Vector2 = _player.global_position
	var lit := _spill(_lit_rects(origin))
	var want := _carry()

	# How far the light gets along each ray: as far as it carries, cut short
	# by walls.
	var reach := PackedFloat32Array()
	reach.resize(SEGMENTS)
	for i in SEGMENTS:
		var a := TAU * i / SEGMENTS
		reach[i] = _wall_limit(origin, Vector2(cos(a), sin(a)), want, lit)

	for b in BANDS:
		var k0: float = lerpf(K_IN, 1.0, float(b) / BANDS)
		var k1: float = lerpf(K_IN, 1.0, float(b + 1) / BANDS)
		_band(origin, reach, k0, k1)
	_shroud(origin, reach, 1.0, Color(DARK, A_MAX))


# How dark it is at a given fraction of the way out along a ray.
func _alpha(k: float) -> float:
	return A_MAX * smoothstep(K_IN, 1.0, k)


# Where the ray leaves the room. Solved exactly against the rectangle edges,
# so the lit area ends flush along a wall instead of in 8px stair-steps.
func _wall_limit(origin: Vector2, dir: Vector2, want: float,
		lit: Array[Rect2]) -> float:
	if _which(origin, lit) == -1:
		# Nowhere known: a pool at your feet rather than the run of the house.
		return minf(want, STRANDED)
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


# One ring of the falloff: a fan of quads whose inner edge sits at k0 along
# each ray and outer edge at k1, with the vertex colours fading the darkness
# across the gap.
func _band(origin: Vector2, reach: PackedFloat32Array, k0: float,
		k1: float) -> void:
	var c0 := Color(DARK, _alpha(k0))
	var c1 := Color(DARK, _alpha(k1))
	var cols := PackedColorArray([c0, c0, c1, c1])
	for i in SEGMENTS:
		var j := (i + 1) % SEGMENTS
		var a0 := TAU * i / SEGMENTS
		var a1 := TAU * (i + 1) / SEGMENTS
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		draw_polygon(PackedVector2Array([
			origin + d0 * reach[i] * k0,
			origin + d1 * reach[j] * k0,
			origin + d1 * reach[j] * k1,
			origin + d0 * reach[i] * k1]), cols)


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
