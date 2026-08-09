extends Node2D

# The lantern has to keep clipping to the room the whole way through a
# doorway. If it ever stops, the beam finds no wall to stop at and the whole
# house lights up through the walls.

const PROBE := 70.0   # how far either side of a doorway to walk


func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var light = get_tree().get_first_node_in_group("light")
	var FP = load("res://scripts/floorplan.gd")
	var fails := 0

	for d in FP.DOORS:
		if d.get("shut", false):
			continue          # nothing on the far side of it to light
		var r: Rect2 = d["rect"]
		var c := r.get_center()
		# walk through the opening, the short way across the wall it sits in
		var step := Vector2(0, 1) if r.size.x >= r.size.y else Vector2(1, 0)
		for dir in [1.0, -1.0]:
			var from: Vector2 = c + step * PROBE * dir
			var to: Vector2 = c - step * PROBE * dir
			light._room = light._room_at(from)
			var bad := 0
			var steps := int(from.distance_to(to))
			for i in steps + 1:
				var p: Vector2 = from.lerp(to, float(i) / steps)
				light._room = light._room_at(p)
				if light._which(p, light._lit_rects(p)) == -1:
					bad += 1
			if bad > 0:
				print("FAIL  doorway at %s, walked from %s: %d spots with no room "
					% [c, from, bad] + "to clip to")
				fails += 1

	print("LIGHT: %s" % ("ALL PASS" if fails == 0 else "%d LEAKS" % fails))
	get_tree().quit()
