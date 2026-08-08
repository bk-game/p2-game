extends Node2D

# Broadleaf tree seen from above, overhanging the cabin as in the plan.

const TRUNK    := Color("6b4a2c")
const TRUNK_LT := Color("8a6440")

# Deep blue-greens, kept well away from the yellow-green of the fume clouds:
# across a dark room the two must never be taken for each other.
const DARK  := Color("1f4420")
const MID   := Color("2c5c28")
const LIGHT := Color("3d7a31")
const LEAF  := Color("4d8f38")


func _draw() -> void:
	# cast shadow, offset down-right
	_canopy(Vector2(26, 30), 1.04, Color(0, 0, 0, 0.16), Color(0, 0, 0, 0.16), 0)

	# trunk and main limbs, visible through the gaps in the foliage
	draw_circle(Vector2.ZERO, 26.0, TRUNK)
	for i in 6:
		var a := TAU * i / 6.0 + 0.4
		var dir := Vector2(cos(a), sin(a))
		draw_line(dir * 12.0, dir * 118.0, TRUNK, 13.0)
		draw_line(dir * 90.0, dir * 118.0 + dir.orthogonal() * 34.0, TRUNK_LT, 7.0)
	draw_circle(Vector2.ZERO, 15.0, TRUNK_LT)

	# three foliage layers, darkest first, so the canopy reads as depth
	_canopy(Vector2(9, 11), 1.0, DARK, MID, 0)
	_canopy(Vector2(0, 0), 0.94, MID, LIGHT, 11)
	_canopy(Vector2(-9, -12), 0.8, LIGHT, LEAF, 23)

	# separate leaves around the edge, which a cloud of gas does not have
	for i in 34:
		var ang := TAU * i / 34.0 + 0.17
		var n := fposmod(sin(i * 91.7) * 43758.5453, 1.0)
		_leaf(Vector2(cos(ang), sin(ang)) * (104.0 + n * 38.0), ang + n,
			11.0 + n * 5.0, LEAF if i % 3 else LIGHT)

	# the boughs again over the canopy, so the shape reads as a tree rather
	# than as a bank of green
	for i in 6:
		var a := TAU * i / 6.0 + 0.4
		var dir := Vector2(cos(a), sin(a))
		draw_line(dir * 20.0, dir * 100.0, Color(TRUNK, 0.7), 8.0)
	draw_circle(Vector2.ZERO, 22.0, TRUNK)
	draw_circle(Vector2.ZERO, 13.0, TRUNK_LT)
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 26, Color(TRUNK_LT, 0.7), 2.0)


# A pointed leaf with a midrib, lying flat along the given angle.
func _leaf(at: Vector2, ang: float, size: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		at - d * size,
		at + n * size * 0.4 - d * size * 0.15,
		at + d * size,
		at - n * size * 0.4 - d * size * 0.15]), col)
	draw_line(at - d * size, at + d * size, Mat.shade(col, 0.72), 1.5)


func _canopy(off: Vector2, scale: float, a: Color, b: Color, seed_i: int) -> void:
	for i in 13:
		var ang := TAU * i / 13.0 + seed_i * 0.31
		var n := fposmod(sin((i + seed_i) * 12.9898) * 43758.5453, 1.0)
		var dist: float = (58.0 + n * 62.0) * scale
		var rad: float = (44.0 + n * 26.0) * scale
		var p := off + Vector2(cos(ang), sin(ang)) * dist
		draw_circle(p, rad, a if i % 2 == 0 else b)
	draw_circle(off, 74.0 * scale, b)
