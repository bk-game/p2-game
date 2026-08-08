extends Node2D

# Spawns every pickup, branch, fume cloud and station from Content, and
# defines their behaviour. Everything interactable joins the "act" group and
# answers prompt()/act().

const BARK      := Color("4a3320")
const BARK_LT   := Color("6d4d2e")
const WEAK      := Color("a97c4a")
const WEAK_LT   := Color("c69a63")
const BRITTLE   := Color("8d8267")
const FUME      := Color(0.42, 0.72, 0.36, 0.34)
const FUME_EDGE := Color(0.35, 0.66, 0.30, 0.5)


func _ready() -> void:
	var stowed := {}
	for c in Content.CONTAINERS:
		for id in c["items"]:
			stowed[id] = true
	for id in Content.ITEMS:
		if id == "bunny" or stowed.has(id):
			continue  # in Joe's hands, or shut inside a cabinet
		var p := Pickup.new()
		p.id = id
		p.position = Content.ITEMS[id]["pos"]
		p.z_index = 30
		add_child(p)
	for b in Content.BRANCHES:
		var n := Branch.new()
		n.setup(b)
		n.z_index = 60
		add_child(n)
	for f in Content.FUMES:
		var n := Fume.new()
		n.position = f["pos"]
		n.radius = f["r"]
		n.z_index = 70
		add_child(n)
	for c in Content.CONTAINERS:
		var box := Container2D.new()
		box.setup(c)
		box.z_index = 28
		add_child(box)
	var body := Station.new()
	body.position = Content.BODY_POS
	body.kind = "body"
	body.z_index = 40
	add_child(body)


# ══ Pickup ═══════════════════════════════════════════════════════════════
class Pickup extends Node2D:
	var id := ""

	func _ready() -> void:
		add_to_group("act")

	func bias() -> float:
		return 45.0

	func prompt() -> String:
		return "Take %s" % Content.ITEMS[id]["name"]

	func act() -> void:
		Sfx.play("pickup", -8.0)
		Game.add_item(id)
		queue_free()

	func _draw() -> void:
		var it: Dictionary = Content.ITEMS[id]
		var tint := Color(it["tint"])
		draw_circle(Vector2(2, 4), 15.0, Color(0, 0, 0, 0.16))
		match it["glyph"]:
			"bottle":
				_shape(Rect2(-9, -14, 18, 28), tint, 4.0)
				_shape(Rect2(-4, -20, 8, 8), Mat.shade(tint, 0.7), 2.0)
				draw_rect(Rect2(-9, -4, 18, 9), Color(1, 1, 1, 0.35))
			"clipboard":
				_shape(Rect2(-13, -17, 26, 34), Color("8a6440"), 3.0)
				_shape(Rect2(-10, -13, 20, 27), tint, 2.0)
				_shape(Rect2(-6, -20, 12, 6), Color("9aa1a7"), 2.0)
				_lines(Rect2(-10, -13, 20, 27), 4)
			"paper", "letter", "scrap":
				_shape(Rect2(-12, -15, 24, 30), tint, 2.0)
				_lines(Rect2(-12, -15, 24, 30), 5)
			"photo":
				_shape(Rect2(-14, -12, 28, 24), Color("f2ecdd"), 2.0)
				_shape(Rect2(-11, -9, 22, 14), tint, 1.0)
			"toy":
				draw_circle(Vector2(0, 3), 11.0, tint)
				draw_circle(Vector2(0, -8), 8.0, tint)
				draw_circle(Vector2(-5, -16), 3.5, tint)
				draw_circle(Vector2(5, -16), 3.5, tint)
			"axe":
				draw_line(Vector2(-3, 18), Vector2(3, -12), Color("8a6440"), 6.0)
				_shape(Rect2(-12, -20, 22, 14), Color("9aa1a7"), 2.0)
			"extinguisher":
				_shape(Rect2(-9, -12, 18, 28), tint, 6.0)
				_shape(Rect2(-4, -19, 8, 8), Color("2c2c31"), 2.0)
			"mask":
				draw_circle(Vector2.ZERO, 14.0, tint)
				draw_circle(Vector2(-5, -3), 5.0, Color("cfe0e4"))
				draw_circle(Vector2(5, -3), 5.0, Color("cfe0e4"))
				draw_circle(Vector2(0, 8), 6.0, Mat.shade(tint, 0.7))
		draw_arc(Vector2.ZERO, 21.0, 0, TAU, 28, Color(1, 0.95, 0.7, 0.5), 2.0)

	func _shape(r: Rect2, c: Color, rad: float) -> void:
		draw_colored_polygon(Mat.rr(r, rad), c)
		var p := Mat.rr(r, rad)
		p.append(p[0])
		draw_polyline(p, Mat.shade(c, 0.65), 1.5)

	func _lines(r: Rect2, n: int) -> void:
		for i in range(1, n):
			var y: float = r.position.y + r.size.y * i / n
			draw_line(Vector2(r.position.x + 3, y), Vector2(r.end.x - 3, y),
				Color(0, 0, 0, 0.3), 1.0)


# ══ Branch ═══════════════════════════════════════════════════════════════
class Branch extends StaticBody2D:
	const CUT_TIME := 2.0
	const CHOP_GAP := 0.55

	const STEPS := 20       # samples along the run, for the outline and grain

	var strong := true
	var brittle := false
	var length := 180.0
	var thick := 30.0
	var cut := 0.0          # seconds of sawing done so far
	var seed_v := 0.0       # fixed per root, so its shape never shifts
	var _chop := 0.0

	func bias() -> float:
		return 0.0

	func setup(d: Dictionary) -> void:
		position = d["pos"]
		rotation = deg_to_rad(d["deg"])
		length = d["len"]
		thick = d["thick"]
		strong = d["strong"]
		seed_v = Mat.noise(d["pos"].x, d["pos"].y) * TAU

	func _ready() -> void:
		add_to_group("act")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(length, thick)
		cs.shape = sh
		add_child(cs)

	# Closest point on the limb itself, so you can prompt anywhere along it
	# rather than only near its midpoint.
	func reach_point(from: Vector2) -> Vector2:
		var l := (from - global_position).rotated(-rotation)
		l.x = clampf(l.x, -length * 0.5, length * 0.5)
		l.y = clampf(l.y, -thick * 0.5, thick * 0.5)
		return global_position + l.rotated(rotation)

	func cuttable() -> bool:
		return not strong or brittle

	func prompt() -> String:
		if cuttable():
			if cut > 0.0:
				return "Cutting through... %d%%" % int(cut / CUT_TIME * 100.0)
			return "Hold E to cut through the limb"
		if Game.solution_charges > 0:
			return "Pour solution on the limb (%d left)" % Game.solution_charges
		return "This limb is too dense to cut"

	# Held-E progress. Returns how far through the cut we are, 0..1.
	func saw(delta: float) -> float:
		if not cuttable():
			return 0.0
		cut += delta
		_chop -= delta
		if _chop <= 0.0:
			_chop = CHOP_GAP
			Sfx.play("chop", -8.0, 1.0 + cut / CUT_TIME * 0.25)
		queue_redraw()
		if cut >= CUT_TIME:
			Sfx.play("crack", -4.0)
			Sfx.play("fall", -8.0)
			Game.toast.emit("The limb splits and falls away.")
			queue_free()
			return 1.0
		return cut / CUT_TIME

	# Let go and the cut closes up again, slower than it opened.
	func relax(delta: float) -> void:
		if cut > 0.0:
			cut = maxf(cut - delta * 0.6, 0.0)
			queue_redraw()

	func act() -> void:
		if cuttable():
			return          # cutting is a hold, handled by the player
		if Game.solution_charges > 0:
			Game.solution_charges -= 1
			brittle = true
			Sfx.play("pour", -7.0)
			Game.toast.emit("The bark blisters and goes grey. It will break now.")
			queue_redraw()
		else:
			Sfx.play("chop", -14.0, 0.7)
			Game.add_note("Dark hardened limbs will not cut. Joe weakened them with a "
				+ "mixture: open the bag with [I], measure the chemicals, press [M].")
			Game.toast.emit("Hardened heartwood — the blade bounces off. Joe softened "
				+ "these with his mixture. Open your bag [I], measure out the chemicals, "
				+ "then press [M] to mix. Pour a dose on this limb to make it brittle.")

	# ── Shape ────────────────────────────────────────────────────────────
	# A root is not a dowel: it wanders off the straight line, swells at the
	# knuckles and thins towards the tip. The collision shape stays the plain
	# rectangle, so the wander and taper are kept small enough that what you
	# walk into is what you see.
	func _mid(t: float) -> Vector2:
		return Vector2(lerpf(-length * 0.5, length * 0.5, t),
			sin(t * 2.7 + seed_v) * thick * 0.13)

	func _half(t: float) -> float:
		var taper: float = 1.0 - 0.24 * t                        # thins to the tip
		var knuckle: float = 1.0 + 0.12 * sin(t * 8.5 + seed_v * 1.7)
		var cap: float = sqrt(clampf(1.0 - pow(2.0 * t - 1.0, 12.0), 0.0, 1.0))
		return thick * 0.5 * taper * knuckle * cap

	func _outline() -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in STEPS + 1:
			var t := float(i) / STEPS
			pts.append(_mid(t) + Vector2(0, -_half(t)))
		for i in STEPS + 1:
			var t := 1.0 - float(i) / STEPS
			pts.append(_mid(t) + Vector2(0, _half(t)))
		return pts

	# A line running the length of the root at a fraction of its half-width,
	# for bark ridges and the highlight along the top.
	func _ridge(off: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(2, STEPS - 1):
			var t := float(i) / STEPS
			pts.append(_mid(t) + Vector2(0, _half(t) * off))
		return pts

	func _draw() -> void:
		var base := EntityColors.pick(strong, brittle)
		var body := _outline()

		for i in 3:   # fine roots fanning off, under the main run
			_rootlet(0.24 + 0.26 * i, 1.0 if i % 2 == 0 else -1.0, base[0])

		var shadow := PackedVector2Array()
		for p in body:
			shadow.append(p + Vector2(2, 3))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.15))
		draw_colored_polygon(body, base[0])

		draw_polyline(_ridge(-0.62), Mat.shade(base[1], 1.06), 2.0)   # lit edge
		draw_polyline(_ridge(-0.12), base[1], 2.0)                    # bark ridges
		draw_polyline(_ridge(0.34), Mat.shade(base[0], 0.82), 2.0)
		draw_polyline(_ridge(0.74), Mat.shade(base[0], 0.66), 2.0)    # shaded edge

		var edge := body
		edge.append(edge[0])            # outline, or pale roots vanish into the
		draw_polyline(edge, Mat.shade(base[0], 0.55), 2.0)   # wood floor

		if brittle:
			for i in 4:
				var t: float = 0.2 + 0.2 * i
				var c := _mid(t)
				var h := _half(t)
				draw_line(c + Vector2(-3, -h + 3), c + Vector2(4, h - 3),
					Color(0.25, 0.22, 0.18, 0.8), 1.5)
		if cut > 0.0:
			_draw_cracks(cut / CUT_TIME)

	# One fine root leaving the side of the run and forking once.
	func _rootlet(t: float, side: float, base: Color) -> void:
		var from := _mid(t) + Vector2(0, _half(t) * side * 0.7)
		var run: float = thick * (0.8 + 0.7 * Mat.noise(t * 31.0, seed_v))
		var d := Vector2(0.45, side).normalized().rotated(
			(Mat.noise(t * 17.0, seed_v + 3.0) - 0.5) * 0.9)
		var mid := from + d * run * 0.6
		var tip := mid + d.rotated(side * 0.5) * run * 0.5
		var w: float = maxf(thick * 0.17, 2.5)
		var col := Mat.shade(base, 0.84)
		draw_line(from, mid, col, w)
		draw_line(mid, tip, col, w * 0.55)
		draw_line(mid, mid + d.rotated(-side * 0.7) * run * 0.35, col, w * 0.45)

	# Splits opening across the grain, more of them and deeper as you saw.
	func _draw_cracks(p: float) -> void:
		var pale := Color(0.93, 0.88, 0.76, 0.9)
		var dark := Color(0.09, 0.07, 0.05, 0.85)
		var count := int(ceil(p * 5.0))
		for i in count:
			var seed_i := float(i) * 7.31
			var t: float = 0.16 + 0.68 * Mat.noise(seed_i, 3.0)
			var grow: float = clampf(p * 1.6 - float(i) * 0.18, 0.0, 1.0)
			if grow <= 0.0:
				continue
			var c := _mid(t)
			var half: float = _half(t) * grow
			var pts := PackedVector2Array()
			var steps := 5
			for k in steps + 1:
				var f: float = float(k) / steps
				var jag: float = (Mat.noise(seed_i + k, 1.7) - 0.5) * thick * 0.34 * grow
				pts.append(c + Vector2(jag, lerpf(-half, half, f)))
			draw_polyline(pts, dark, maxf(1.5, 3.5 * grow))
			draw_polyline(pts, pale, maxf(1.0, 1.4 * grow))
		# the whole root sags as it gives way
		if p > 0.55:
			var open: float = (p - 0.55) / 0.45
			draw_polyline(_ridge(0.0), Color(0.08, 0.06, 0.04, 0.5 * open),
				2.0 + 5.0 * open)


class EntityColors:
	static func pick(strong: bool, brittle: bool) -> Array:
		if brittle:
			return [Color("8d8267"), Color("a2977c")]
		if strong:
			return [Color("4a3320"), Color("6d4d2e")]
		return [Color("a97c4a"), Color("c69a63")]


# ══ Fume cloud ═══════════════════════════════════════════════════════════
class Fume extends Node2D:
	var radius := 100.0
	var _t := 0.0

	func _ready() -> void:
		add_to_group("act")

	func bias() -> float:
		return 8.0

	# The cloud pushes you out at 0.72r, which for the big one is further than
	# the player can reach. Prompt from the edge of the cloud, not its centre.
	func reach_point(from: Vector2) -> Vector2:
		var edge := radius * 0.72
		var d := from - global_position
		if d.length() < 0.01:
			return global_position + Vector2(edge, 0.0)
		return global_position + d.normalized() * edge

	func prompt() -> String:
		if Game.has_item("extinguisher") and Game.extinguisher_charges > 0:
			return "Blow the air clear (%d charges)" % Game.extinguisher_charges
		return "Choking green haze"

	func act() -> void:
		if Game.has_item("extinguisher") and Game.extinguisher_charges > 0:
			Game.extinguisher_charges -= 1
			Sfx.play("whoosh", -4.0)
			Game.toast.emit("The powder knocks the haze out of the air.")
			queue_free()
		else:
			Game.toast.emit("You cannot clear this by hand. Something would have to "
				+ "blow it out.")

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		var p := get_tree().get_first_node_in_group("player")
		if p == null or Game.has_item("gasmask"):
			return
		if p.global_position.distance_to(global_position) < radius * 0.72:
			p.global_position = Content.ENTRANCE
			Sfx.play("choke", -5.0)
			Game.toast.emit("Your throat closes and everything goes white. You come to "
				+ "on the doorstep. You need clean air to go in there.")

	func _draw() -> void:
		for i in 7:
			var a := TAU * i / 7.0 + _t * 0.25
			var d := radius * 0.42
			draw_circle(Vector2(cos(a), sin(a)) * d, radius * 0.6, FUME)
		draw_circle(Vector2.ZERO, radius * 0.66, FUME)
		draw_arc(Vector2.ZERO, radius * 0.72, 0, TAU, 40, FUME_EDGE, 2.0)


# ══ Station: mixing bench and Joe's body ═════════════════════════════════
class Station extends Node2D:
	var kind := "bench"
	var examined := false

	func _ready() -> void:
		add_to_group("act")

	func bias() -> float:
		return 45.0

	func prompt() -> String:
		if kind == "bench":
			return "Mix chemicals at the bench"
		return "Examine the body" if not examined else "Take the bunny from his hands"

	func act() -> void:
		if kind == "bench":
			Game.open_bench.emit()
			return
		if not examined:
			examined = true
			Game.add_note("Joe Wood died here. A tree is growing out through his chest.")
			Game.notice.emit("Joe Wood", "A big man in a red-and-yellow flannel shirt, "
				+ "blue jeans, brown boots gone green with mould. He is sitting against "
				+ "the wall.\n\nA trunk the thickness of your wrist has come up out of "
				+ "his chest and gone on up through the ceiling. The bark is continuous "
				+ "with him. It did not fall on him — it started inside.\n\nHis hands are "
				+ "folded around something soft.")
			queue_redraw()
		else:
			Game.add_item("bunny")
			queue_redraw()

	func _draw() -> void:
		if kind == "bench":
			draw_arc(Vector2.ZERO, 20.0, 0, TAU, 26, Color(1, 0.95, 0.7, 0.45), 2.0)
			draw_circle(Vector2.ZERO, 7.0, Color("c69a63"))
			return
		# Joe: flannel torso, boots, and the trunk coming through him
		draw_circle(Vector2(3, 5), 34.0, Color(0, 0, 0, 0.18))
		draw_colored_polygon(Mat.rr(Rect2(-26, -22, 52, 46), 12.0), Color("a8352c"))
		for i in 4:
			draw_line(Vector2(-26, -14.0 + i * 11.0), Vector2(26, -14.0 + i * 11.0),
				Color("d8b13a"), 3.0)
			draw_line(Vector2(-19.0 + i * 13.0, -22), Vector2(-19.0 + i * 13.0, 24),
				Color("d8b13a"), 3.0)
		draw_colored_polygon(Mat.rr(Rect2(-20, 20, 16, 22), 5.0), Color("4a3320"))
		draw_colored_polygon(Mat.rr(Rect2(4, 20, 16, 22), 5.0), Color("4a3320"))
		draw_circle(Vector2(0, -30), 15.0, Color("9aa87e"))  # greened skin
		draw_circle(Vector2(0, 0), 15.0, Color("4a3320"))    # trunk through chest
		draw_circle(Vector2(0, 0), 9.0, Color("6d4d2e"))
		if examined:
			return
		draw_arc(Vector2.ZERO, 44.0, 0, TAU, 34, Color(1, 0.95, 0.7, 0.4), 2.0)


# ══ Container: a cabinet or drawer you have to open ══════════════════════
class Container2D extends Node2D:
	# Drawers and cupboards are a piece of furniture rather than a point, so
	# they open from further off than you can cut a limb from.
	const OPEN_REACH := 62.0

	var label := ""
	var items: Array = []
	var opened := false

	func bias() -> float:
		return 18.0

	func reach() -> float:
		return OPEN_REACH

	func setup(d: Dictionary) -> void:
		position = d["pos"]
		items = d["items"]

	func _ready() -> void:
		add_to_group("act")

	func prompt() -> String:
		return "Open"

	func act() -> void:
		if opened or items.is_empty():
			opened = true
			Sfx.play("empty", -10.0)
			Game.toast.emit("Empty.")
			return
		opened = true
		Sfx.play("open", -8.0)
		if items.is_empty():
			Game.toast.emit("Empty.")
			return
		var names: Array[String] = []
		for i in items.size():
			var pk := Pickup.new()
			pk.id = items[i]
			pk.position = position + Vector2(-22.0 + i * 44.0, 26)
			pk.z_index = 30
			get_parent().add_child(pk)
			names.append(Content.ITEMS[items[i]]["name"])
		Game.toast.emit("Inside: %s." % ", ".join(names))
