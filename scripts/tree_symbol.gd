extends Node2D

# Broadleaf tree seen from above, overhanging the cabin as in the plan.

const TRUNK    := Color("6b4a2c")
const TRUNK_LT := Color("8a6440")


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
	_canopy(Vector2(9, 11), 1.0, Color("2f5626"), Color("35602b"), 0)
	_canopy(Vector2(0, 0), 0.94, Color("467a34"), Color("4d8639"), 11)
	_canopy(Vector2(-9, -12), 0.8, Color("63a047"), Color("6fae4f"), 23)


func _canopy(off: Vector2, scale: float, a: Color, b: Color, seed_i: int) -> void:
	for i in 13:
		var ang := TAU * i / 13.0 + seed_i * 0.31
		var n := fposmod(sin((i + seed_i) * 12.9898) * 43758.5453, 1.0)
		var dist: float = (58.0 + n * 62.0) * scale
		var rad: float = (44.0 + n * 26.0) * scale
		var p := off + Vector2(cos(ang), sin(ang)) * dist
		draw_circle(p, rad, a if i % 2 == 0 else b)
	draw_circle(off, 74.0 * scale, b)
