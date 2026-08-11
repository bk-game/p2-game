extends Node2D

const T := 37.0  # wall thickness

const C_EXTERIOR := Color("dfe6e3")

# ── Walls: non-overlapping tiles that close every room ────────────────────
const WALLS: Array[Rect2] = [
	Rect2(275, 57, 1032, 37),    # top exterior
	Rect2(1270, 94, 37, 123),    # upper-right return
	Rect2(1307, 180, 143, 37),   # step out to bedroom
	Rect2(1413, 217, 37, 361),   # bedroom right exterior
	Rect2(1413, 578, 237, 37),   # living-room top exterior (right wing)
	Rect2(1613, 615, 37, 363),   # right exterior
	Rect2(65, 978, 1585, 37),    # bottom exterior
	Rect2(65, 452, 37, 526),     # left exterior
	Rect2(65, 415, 247, 37),     # left step
	Rect2(275, 94, 37, 321),     # kitchen left wall (upper)
	Rect2(275, 452, 37, 148),    # kitchen left wall (lower)
	Rect2(890, 94, 37, 86),      # kitchen/bath divider
	Rect2(890, 217, 37, 383),    # kitchen/bedroom divider
	Rect2(890, 180, 417, 37),    # bathroom bottom wall
	Rect2(275, 600, 652, 37),    # kitchen bottom wall
	Rect2(927, 578, 486, 37),    # bedroom bottom wall
	Rect2(450, 637, 37, 341),    # store / living divider
	Rect2(65, 57, 247, 37),      # hidden shed: north
	Rect2(65, 94, 37, 321),      # hidden shed: west

	# ── The office you work out of, off to the west of the cabin ─────────
	# Far enough away that the two never share a wall; you only ever get
	# from one to the other through a door.
	Rect2(-820, 120, 597, 37),   # office: north
	Rect2(-820, 157, 37, 429),   # office: west
	Rect2(-820, 549, 597, 37),   # office: south
	Rect2(-260, 157, 37, 429),   # office: east
	Rect2(-571, 157, 22, 429),   # office: lift lobby divider
	Rect2(-783, 338, 212, 30),   # office: between the two lifts
]

# ── Doors: opening rect, hinge, swing radius and arc ──────────────────────
const DOORS := [
	{"rect": Rect2(620, 600, 70, 37),  "hinge": Vector2(620, 600),  "r": 70.0,
		"a0": -PI / 2, "a1": 0.0,  "leaf": -PI / 2, "ext": false},
	{"rect": Rect2(950, 180, 80, 37),  "hinge": Vector2(1030, 217), "r": 80.0,
		"a0": PI / 2,  "a1": PI,   "leaf": PI / 2 - 0.08, "ext": false},
	{"rect": Rect2(1272, 578, 70, 37), "hinge": Vector2(1272, 578), "r": 70.0,
		"a0": -PI / 2, "a1": 0.0,  "leaf": -PI / 2, "ext": false},
	{"rect": Rect2(450, 700, 37, 90),  "hinge": Vector2.ZERO,       "r": 0.0,
		"a0": 0.0,     "a1": 0.0,  "leaf": 0.0, "ext": false},
	{"rect": Rect2(1418, 978, 88, 37), "hinge": Vector2(1418, 978), "r": 88.0,
		"a0": -PI / 2, "a1": 0.0,  "leaf": -PI / 2, "ext": true},  # front entrance
	{"rect": Rect2(212, 415, 60, 37), "hinge": Vector2.ZERO,      "r": 0.0,
		"a0": 0.0,     "a1": 0.0,  "leaf": 0.0, "ext": false},     # hidden shed door
	# ── office ──────────────────────────────────────────────────────────
	{"rect": Rect2(-571, 230, 22, 60), "hinge": Vector2.ZERO,     "r": 0.0,
		"a0": 0.0,     "a1": 0.0,  "leaf": 0.0, "ext": false},     # lift, upstairs
	{"rect": Rect2(-571, 440, 22, 60), "hinge": Vector2.ZERO,     "r": 0.0,
		"a0": 0.0,     "a1": 0.0,  "leaf": 0.0, "ext": false},     # store cupboard
	# The way out to the job. Shut: you leave through it by using it, not by
	# walking through the wall, so it is not cut out of the wall.
	{"rect": Rect2(-420, 549, 88, 37), "hinge": Vector2(-332, 549), "r": 88.0,
		"a0": PI, "a1": PI * 1.5, "leaf": PI, "ext": true, "shut": true},
]

const WINDOWS: Array[Rect2] = [
	Rect2(560, 57, 100, 37),    # kitchen, north
	Rect2(275, 200, 37, 90),    # kitchen, west
	Rect2(1413, 350, 37, 110),  # bedroom, east
	Rect2(65, 590, 37, 100),    # store, west
	Rect2(65, 700, 37, 90),     # store, west
	Rect2(740, 978, 90, 37),    # living, south
	Rect2(1240, 978, 90, 37),   # living, south
]

const FLOORS := [
	{"r": Rect2(312, 94, 578, 506),  "p": "stone"},
	{"r": Rect2(927, 94, 343, 86),   "p": "ceramic"},
	{"r": Rect2(927, 217, 486, 361), "p": "wood"},
	{"r": Rect2(102, 452, 173, 526), "p": "wood"},
	{"r": Rect2(275, 637, 175, 341), "p": "wood"},
	{"r": Rect2(487, 615, 1126, 363),"p": "wood"},
	{"r": Rect2(102, 94, 173, 321), "p": "stone"},
	# ── office ──────────────────────────────────────────────────────────
	{"r": Rect2(-783, 157, 212, 181), "p": "ceramic"},   # lift, upstairs
	{"r": Rect2(-783, 368, 212, 181), "p": "stone"},     # store cupboard
	{"r": Rect2(-549, 157, 289, 392), "p": "carpet"},    # the floor you work on
]

# ── Yard: a hedge boxing in the front path ───────────────────────────────
# Nothing is modelled past the path, so the walk out of the front door stops
# at the hedge rather than carrying on into empty grass.
const HEDGE: Array[Rect2] = [
	Rect2(1360, 1015, 26, 174),   # west of the path
	Rect2(1538, 1015, 26, 174),   # east of the path
	Rect2(1360, 1189, 204, 26),   # foot of the path
]

const SOLIDS: Array[Rect2] = [
	Rect2(312, 94, 428, 66),    # kitchen counter run
	Rect2(312, 200, 48, 380),   # pantry
	Rect2(360, 490, 90, 90),    # base cabinet
	Rect2(460, 262, 230, 106),  # dining table
	Rect2(740, 530, 130, 70),   # sideboard
	Rect2(958, 88, 64, 60),     # vanity
	Rect2(1185, 95, 85, 85),    # shower
	Rect2(1108, 138, 48, 48),   # toilet
	Rect2(920, 435, 180, 143),  # bed
	Rect2(1196, 552, 42, 26),   # nightstand
	Rect2(1332, 262, 74, 66),   # armchair
	Rect2(830, 617, 370, 83),   # sofa back
	Rect2(1140, 700, 60, 140),  # sofa chaise
	Rect2(920, 745, 140, 55),   # coffee table
	Rect2(700, 640, 120, 48),   # writing desk
	Rect2(1413, 617, 147, 43),  # sideboard
	Rect2(102, 452, 98, 38),    # workbench
	Rect2(206, 926, 98, 52),    # wood stove
	Rect2(115, 890, 78, 88),    # firewood

	# ── office ──────────────────────────────────────────────────────────
	Rect2(-380, 240, 56, 250),  # the desk, with the two of them behind it
	Rect2(-306, 262, 46, 46),   # chair, back to the wall
	Rect2(-306, 420, 46, 46),   # chair
	Rect2(-300, 172, 34, 50),   # filing cabinets
	Rect2(-540, 176, 32, 36),   # water cooler
	Rect2(-543, 300, 62, 46),   # printer on its stand
	Rect2(-296, 490, 36, 36),   # the plant nobody waters
	Rect2(-777, 386, 36, 150),  # store: shelving down the wall
	Rect2(-700, 500, 60, 40),   # store: crates
]

var _pieces: Array[Rect2] = []


func _ready() -> void:
	_pieces = _split_walls()
	for r in _pieces:
		_add_body(r)
	for r in SOLIDS:
		_add_body(r)
	for r in HEDGE:
		_add_body(r)


func _split_walls() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for w in WALLS:
		var parts: Array[Rect2] = [w]
		for d in DOORS:
			if d.get("shut", false):
				continue          # a door that is never walked through
			var next: Array[Rect2] = []
			for p in parts:
				next.append_array(_subtract(p, d["rect"]))
			parts = next
		out.append_array(parts)
	return out


func _subtract(a: Rect2, b: Rect2) -> Array[Rect2]:
	if not a.intersects(b):
		return [a]
	var i := a.intersection(b)
	var out: Array[Rect2] = []
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


func _add_body(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = r.get_center()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


# ══ Drawing ══════════════════════════════════════════════════════════════
func _draw() -> void:
	draw_rect(Rect2(-300, -300, 2400, 1700), C_EXTERIOR)
	_ground()
	_hedge()
	for f in FLOORS:
		match f["p"]:
			"wood": _wood_floor(f["r"])
			"stone": _stone_floor(f["r"])
			"carpet": _carpet_floor(f["r"])
			_: _ceramic_floor(f["r"])
	for d in DOORS:
		draw_rect((d["rect"] as Rect2).grow(1.0),
			Mat.WOOD if not d["ext"] else Mat.STONE)
	_draw_walls()
	for w in WINDOWS:
		_window(w)
	for d in DOORS:
		if d["r"] > 0.0:
			_door(d)
	_office()
	_kitchen()
	_bathroom()
	_bedroom()
	_living()
	_store()


# Grass and a path up to the front door, so the outside isn't flat.
func _ground() -> void:
	var g := Color("9fb089")
	draw_rect(Rect2(-300, -300, 2400, 1700), g)
	for i in 900:
		var x := Mat.noise(i * 1.7, 3.1) * 2400.0 - 300.0
		var y := Mat.noise(i * 2.3, 7.7) * 1700.0 - 300.0
		draw_line(Vector2(x, y), Vector2(x + 3, y - 6), Mat.shade(g, 0.93), 1.0)
	_fill(Rect2(-860, 80, 677, 546), Color("9d9d9a"))    # the floor slab it sits on
	_fill(Rect2(1408, 1015, 108, 200), Color("c2b9a4"), 6.0)
	for i in 7:
		draw_line(Vector2(1408, 1040.0 + i * 24.0), Vector2(1516, 1040.0 + i * 24.0),
			Color("aca392"), 1.5)


# Overgrown planting along the path, drawn as clumps so it reads as a hedge
# you cannot push through rather than a kerb.
func _hedge() -> void:
	for r in HEDGE:
		_fill(Rect2(r.position + Vector2(3, 4), r.size), Mat.SHADOW, 10.0)
		_fill(r, Mat.shade(Mat.LEAF, 0.78), 10.0)
		var horiz := r.size.x >= r.size.y
		var run: float = r.size.x if horiz else r.size.y
		var n := int(run / 21.0)
		for i in n:
			var t: float = (i + 0.5) / n
			var c := r.get_center()
			if horiz:
				c.x = lerpf(r.position.x, r.end.x, t)
			else:
				c.y = lerpf(r.position.y, r.end.y, t)
			var s: float = 0.88 + 0.3 * Mat.noise(i, r.position.x)
			draw_circle(c, 14.0, Mat.shade(Mat.LEAF, s))
			draw_circle(c + Vector2(-3, -3), 7.0, Mat.shade(Mat.LEAF, s * 1.18))


# Contract carpet: flat, cheap, and laid in squares that do not quite line up.
func _carpet_floor(r: Rect2) -> void:
	draw_rect(r, Mat.CARPET)
	const T := 46.0
	var cy := int(floor(r.position.y / T))
	var y: float = cy * T
	while y < r.end.y:
		var cx := int(floor(r.position.x / T))
		var x: float = cx * T
		while x < r.end.x:
			var c := Rect2()
			c.position = Vector2(maxf(x, r.position.x), maxf(y, r.position.y))
			c.end = Vector2(minf(x + T, r.end.x), minf(y + T, r.end.y))
			var s: float = 0.97 + 0.06 * Mat.noise(cx, cy)
			draw_rect(c, Mat.shade(Mat.CARPET, s))
			# the pile catches the light one way in every other square
			if (cx + cy) % 2 == 0:
				draw_rect(Rect2(c.position, c.size * Vector2(1.0, 0.5)),
					Mat.shade(Mat.CARPET, s * 1.04))
			x += T
			cx += 1
		y += T
		cy += 1


func _wood_floor(r: Rect2) -> void:
	draw_rect(r, Mat.WOOD)
	const H := 27.0
	const L := 230.0
	var row := int(floor(r.position.y / H))
	var y := row * H
	while y < r.end.y:
		var top: float = max(y, r.position.y)
		var bot: float = min(y + H, r.end.y)
		var x: float = r.position.x - L + fposmod(row * 83.0, L)
		while x < r.end.x:
			var l: float = max(x, r.position.x)
			var rr: float = min(x + L, r.end.x)
			if rr - l > 0.5:
				var s: float = 0.93 + 0.13 * Mat.noise(row, floor(x))
				draw_rect(Rect2(l, top, rr - l, bot - top), Mat.shade(Mat.WOOD, s))
				# grain streaks
				for k in 2:
					var gy: float = top + (bot - top) * (0.3 + 0.36 * k)
					draw_line(Vector2(l + 6, gy), Vector2(rr - 6, gy),
						Mat.shade(Mat.WOOD, s * 0.9), 1.0)
				if rr < r.end.x:
					draw_line(Vector2(rr, top), Vector2(rr, bot), Mat.WOOD_LINE, 1.5)
			x += L
		if bot < r.end.y:
			draw_line(Vector2(r.position.x, bot), Vector2(r.end.x, bot), Mat.WOOD_LINE, 1.5)
		y += H
		row += 1


func _stone_floor(r: Rect2) -> void:
	_grid_floor(r, 74.0, Mat.STONE, Mat.STONE_LINE, 0.055)


func _ceramic_floor(r: Rect2) -> void:
	_grid_floor(r, 34.0, Mat.CERAMIC, Mat.CERAMIC_LN, 0.03)


func _grid_floor(r: Rect2, size: float, base: Color, line: Color, vary: float) -> void:
	draw_rect(r, base)
	var cy := int(floor(r.position.y / size))
	var y := cy * size
	while y < r.end.y:
		var cx := int(floor(r.position.x / size))
		var x := cx * size
		while x < r.end.x:
			var c := Rect2()
			c.position = Vector2(max(x, r.position.x), max(y, r.position.y))
			c.end = Vector2(min(x + size, r.end.x), min(y + size, r.end.y))
			var s: float = 1.0 - vary * 0.5 + vary * Mat.noise(cx, cy)
			draw_rect(c, Mat.shade(base, s))
			x += size
			cx += 1
		y += size
		cy += 1
	var gx: float = floor(r.position.x / size) * size
	while gx < r.end.x:
		if gx > r.position.x:
			draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), line, 2.0)
		gx += size
	var gy: float = floor(r.position.y / size) * size
	while gy < r.end.y:
		if gy > r.position.y:
			draw_line(Vector2(r.position.x, gy), Vector2(r.end.x, gy), line, 2.0)
		gy += size


func _draw_walls() -> void:
	for r in _pieces:
		draw_rect(r, Mat.WALL)
	for r in _pieces:  # timber grain along the run of each wall
		var horiz := r.size.x >= r.size.y
		var n := int((r.size.y if horiz else r.size.x) / 9.0)
		for i in range(1, n):
			var t: float = float(i) / n
			var c := Mat.shade(Mat.WALL_GRAIN, 0.94 + 0.12 * Mat.noise(i, r.position.x))
			if horiz:
				var yy: float = r.position.y + r.size.y * t
				draw_line(Vector2(r.position.x, yy), Vector2(r.end.x, yy), c, 1.5)
			else:
				var xx: float = r.position.x + r.size.x * t
				draw_line(Vector2(xx, r.position.y), Vector2(xx, r.end.y), c, 1.5)
	for r in _pieces:
		_edge(r, Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(0, -1))
		_edge(r, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2(0, 1))
		_edge(r, Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y), Vector2(-1, 0))
		_edge(r, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y), Vector2(1, 0))


func _edge(_r: Rect2, a: Vector2, b: Vector2, outward: Vector2) -> void:
	var len := a.distance_to(b)
	var dir := (b - a).normalized()
	var step := 6.0
	var run := -1.0
	var t := 0.0
	while t <= len:
		var probe: Vector2 = a + dir * min(t + step * 0.5, len) + outward * 3.0
		var open := not _wall_at(probe)
		if open and run < 0.0:
			run = t
		elif not open and run >= 0.0:
			draw_line(a + dir * run, a + dir * t, Mat.WALL_EDGE, 2.5)
			run = -1.0
		t += step
	if run >= 0.0:
		draw_line(a + dir * run, b, Mat.WALL_EDGE, 2.5)


func _wall_at(p: Vector2) -> bool:
	for r in _pieces:
		if r.has_point(p):
			return true
	return false


func _window(r: Rect2) -> void:
	var horiz := r.size.x > r.size.y
	_fill(r, Mat.OAK_DK, 2.0)                       # frame
	var g := r.grow(-6.0)
	_fill(g, Mat.GLASS, 1.0)
	# glazing bars + a highlight streak
	if horiz:
		draw_line(Vector2(g.get_center().x, g.position.y),
			Vector2(g.get_center().x, g.end.y), Mat.OAK_DK, 3.0)
		draw_line(Vector2(g.position.x + 4, g.position.y + 5),
			Vector2(g.end.x - 4, g.position.y + 5), Color(1, 1, 1, 0.5), 3.0)
	else:
		draw_line(Vector2(g.position.x, g.get_center().y),
			Vector2(g.end.x, g.get_center().y), Mat.OAK_DK, 3.0)
		draw_line(Vector2(g.position.x + 5, g.position.y + 4),
			Vector2(g.position.x + 5, g.end.y - 4), Color(1, 1, 1, 0.5), 3.0)
	_stroke(r, Mat.WALL_EDGE, 2.0, 2.0)


func _door(d: Dictionary) -> void:
	var h: Vector2 = d["hinge"]
	var rad: float = d["r"]
	draw_arc(h, rad, d["a0"], d["a1"], 48, Color(0, 0, 0, 0.16), 2.0)
	var dir := Vector2(cos(d["leaf"]), sin(d["leaf"]))
	var n := dir.orthogonal() * 6.0
	var tip := h + dir * rad
	var leaf := PackedVector2Array([h - n, tip - n, tip + n, h + n])
	draw_colored_polygon(leaf, Mat.OAK)
	# panel detail along the leaf
	draw_line(h + dir * 10.0, tip - dir * 10.0, Mat.shade(Mat.OAK, 0.85), 2.0)
	leaf.append(leaf[0])
	draw_polyline(leaf, Mat.OAK_DK, 2.0)
	draw_circle(tip - dir * 12.0, 3.5, Mat.BRASS)


# ── Shape helpers ────────────────────────────────────────────────────────
func _fill(r: Rect2, c: Color, rad := 0.0) -> void:
	if rad <= 0.0:
		draw_rect(r, c)
	else:
		draw_colored_polygon(Mat.rr(r, rad), c)


func _stroke(r: Rect2, c: Color, w := 2.0, rad := 0.0) -> void:
	if rad <= 0.0:
		draw_rect(r, c, false, w)
	else:
		var p := Mat.rr(r, rad)
		p.append(p[0])
		draw_polyline(p, c, w)


# Filled shape with a soft drop shadow and a darker outline.
func _obj(r: Rect2, c: Color, rad := 3.0, edge := Color(0, 0, 0, 0)) -> void:
	_fill(Rect2(r.position + Vector2(2, 3), r.size), Mat.SHADOW, rad)
	_fill(r, c, rad)
	_stroke(r, edge if edge.a > 0.0 else Mat.shade(c, 0.72), 2.0, rad)


func _oval(c: Vector2, rx: float, ry: float, fill: Color, edge := Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, edge if edge.a > 0.0 else Mat.shade(fill, 0.72), 2.0)


# Wood grain streaks inside a rect.
func _grain(r: Rect2, base: Color, horiz := true, n := 5) -> void:
	for i in range(1, n):
		var t: float = float(i) / n
		var c := Mat.shade(base, 0.88 + 0.1 * Mat.noise(i, r.position.x))
		if horiz:
			var y: float = r.position.y + r.size.y * t
			draw_line(Vector2(r.position.x + 4, y), Vector2(r.end.x - 4, y), c, 1.5)
		else:
			var x: float = r.position.x + r.size.x * t
			draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y - 4), c, 1.5)


# Upholstery: rounded pad with a seam inset.
func _cushion(r: Rect2, c: Color) -> void:
	_obj(r, c, 8.0)
	_stroke(r.grow(-6.0), Mat.shade(c, 0.86), 1.5, 6.0)


# ── The office ───────────────────────────────────────────────────────────
func _office() -> void:
	# the desk runs down the room and the two of you sit behind it, backs to
	# the wall, facing whoever comes off the lifts
	var desk := Rect2(-380, 240, 56, 250)
	_obj(desk, Mat.PORCELAIN, 3.0)
	_stroke(desk.grow(-5.0), Mat.shade(Mat.PORC_SH, 0.94), 1.5, 2.0)
	for y in [268.0, 426.0]:
		_obj(Rect2(-356, y, 16, 40), Mat.IRON, 2.0)          # screen, edge on
		_fill(Rect2(-360, y + 3, 4, 34), Mat.GLASS, 1.0)
		_obj(Rect2(-378, y + 12, 14, 30), Mat.STEEL, 2.0)    # keyboard
	for c in [Vector2(-356, 252), Vector2(-356, 478)]:       # a mug each, cold
		draw_circle(c, 7.0, Mat.PORCELAIN)
		draw_circle(c, 5.0, Color("6b4a2c"))
	for c in [Rect2(-306, 262, 46, 46), Rect2(-306, 420, 46, 46)]:
		_obj(c, Mat.PORCELAIN, 8.0)
		_stroke(c.grow(-6.0), Mat.PORC_SH, 1.5, 6.0)

	# filing cabinet in the corner, one drawer left open
	_obj(Rect2(-300, 172, 34, 50), Mat.STEEL, 2.0)
	_stroke(Rect2(-296, 176, 26, 20), Mat.STEEL_DK, 1.5, 2.0)
	draw_line(Vector2(-290, 186), Vector2(-276, 186), Mat.STEEL_DK, 2.5)
	_fill(Rect2(-296, 200, 34, 18), Mat.shade(Mat.STEEL, 0.88), 2.0)
	_fill(Rect2(-290, 204, 22, 10), Mat.LINEN, 1.0)

	# water cooler
	_obj(Rect2(-540, 176, 32, 36), Mat.STEEL, 3.0)
	_fill(Rect2(-536, 180, 24, 20), Mat.GLASS, 3.0)
	draw_circle(Vector2(-524, 206), 3.0, Mat.STEEL_DK)

	# printer on its stand, with a tray of paper out
	_obj(Rect2(-543, 300, 62, 46), Mat.IRON, 3.0)
	_fill(Rect2(-537, 306, 50, 20), Mat.IRON_LT, 2.0)
	_fill(Rect2(-533, 326, 42, 14), Mat.LINEN, 1.0)
	draw_circle(Vector2(-490, 310), 2.5, Mat.EMBER)

	# the plant nobody waters
	_oval(Vector2(-278, 508), 18, 18, Mat.OAK_DK)
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var d2 := Vector2(cos(a), sin(a))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-278, 508) + d2.orthogonal() * 4.0,
			Vector2(-278, 508) + d2 * 26.0,
			Vector2(-278, 508) - d2.orthogonal() * 4.0]),
			Mat.shade(Mat.LEAF, 0.85 + 0.3 * Mat.noise(i, 2.0)))
	draw_circle(Vector2(-278, 508), 8.0, Mat.shade(Mat.OAK_DK, 1.2))

	# clock and strip light on the north wall
	draw_circle(Vector2(-470, 146), 14.0, Mat.PORCELAIN)
	draw_arc(Vector2(-470, 146), 14.0, 0, TAU, 22, Mat.STEEL_DK, 2.0)
	draw_line(Vector2(-470, 146), Vector2(-470, 138), Mat.IRON, 2.0)
	draw_line(Vector2(-470, 146), Vector2(-464, 149), Mat.IRON, 1.5)
	_fill(Rect2(-500, 168, 90, 10), Color("f2f2e6"), 3.0)
	_stroke(Rect2(-500, 168, 90, 10), Mat.STEEL_DK, 1.5, 3.0)

	# the board by the door, where the job comes from
	_obj(Rect2(-400, 160, 120, 16), Mat.OAK_DK, 2.0)
	_fill(Rect2(-394, 162, 44, 12), Mat.LINEN, 1.0)
	_fill(Rect2(-344, 162, 58, 12), Mat.LINEN_DK, 1.0)

	# the lift car: a steel floor and a seam where the doors part
	var car := Rect2(-783, 157, 212, 181)
	_fill(car.grow(-6.0), Mat.shade(Mat.STEEL, 0.94), 2.0)
	_stroke(car.grow(-6.0), Mat.STEEL_DK, 2.0, 2.0)
	for i in 5:
		var x2: float = car.position.x + 20.0 + i * 42.0
		draw_line(Vector2(x2, car.position.y + 10),
			Vector2(x2, car.end.y - 10), Mat.shade(Mat.STEEL, 0.86), 1.5)
	_fill(Rect2(-571, 230, 22, 60), Mat.STEEL, 1.0)
	draw_line(Vector2(-560, 234), Vector2(-560, 286), Mat.STEEL_DK, 2.5)
	_fill(Rect2(-547, 252, 6, 16), Mat.IRON, 1.0)
	draw_circle(Vector2(-544, 260), 2.0, Mat.EMBER)

	# the store cupboard: shelving down the wall, crates, a bare bulb
	var shelf := Rect2(-777, 386, 36, 150)
	_obj(shelf, Mat.OAK_DK, 2.0)
	for i in 4:
		var sy: float = 392.0 + i * 36.0
		draw_line(Vector2(-775, sy), Vector2(-743, sy), Mat.shade(Mat.OAK_DK, 1.3), 2.0)
		_fill(Rect2(-772.0 + fposmod(i * 7.0, 9.0), sy + 6.0, 14, 20),
			Mat.LINEN_DK if i % 2 == 0 else Mat.STEEL, 1.0)
	_obj(Rect2(-700, 500, 60, 40), Mat.OAK, 2.0)
	draw_line(Vector2(-700, 520), Vector2(-640, 520), Mat.OAK_DK, 2.0)
	_fill(Rect2(-694, 490, 42, 26), Mat.OAK, 2.0)
	draw_circle(Vector2(-660, 420), 9.0, Color("f2f2e6"))
	draw_arc(Vector2(-660, 420), 9.0, 0, TAU, 16, Mat.STEEL_DK, 1.5)
	_fill(Rect2(-571, 440, 22, 60), Mat.WOOD, 1.0)          # the cupboard door
	draw_circle(Vector2(-556, 470), 3.0, Mat.BRASS)

	# the fire door out to the yard, with three barrels down its edge
	var out := Rect2(-420, 549, 88, 37)
	_fill(out, Mat.STEEL, 1.0)
	_stroke(out, Mat.STEEL_DK, 2.0)
	draw_line(Vector2(-412, 566), Vector2(-340, 566), Mat.STEEL_DK, 4.0)  # push bar
	for i in 3:
		var bx: float = -406.0 + i * 30.0
		draw_circle(Vector2(bx, 555), 5.0, Mat.BRASS)
		draw_circle(Vector2(bx, 555), 2.5, Mat.shade(Mat.BRASS, 0.55))
	_fill(Rect2(-402, 528, 52, 14), Color("1f6b2f"), 2.0)                 # EXIT sign
	draw_line(Vector2(-394, 535), Vector2(-360, 535), Color("d9f2dd"), 3.0)

	# the key press on the lobby wall
	_fill(Rect2(-549, 330, 8, 40), Mat.OAK_DK, 1.0)


# ── Kitchen ──────────────────────────────────────────────────────────────
func _kitchen() -> void:
	var run := Rect2(312, 94, 428, 66)
	_fill(Rect2(run.position + Vector2(2, 3), run.size), Mat.SHADOW, 2.0)
	# cabinet bank under a butcher-block top
	_fill(Rect2(312, 94, 128, 66), Mat.CAB, 2.0)
	for i in 2:
		var d := Rect2(318.0 + i * 61.0, 100, 55, 54)
		_stroke(d, Mat.CAB_DK, 1.5, 3.0)
		draw_line(Vector2(d.end.x - 8, d.get_center().y - 7),
			Vector2(d.end.x - 8, d.get_center().y + 7), Mat.STEEL_DK, 3.0)
	# dishwasher
	_fill(Rect2(440, 94, 120, 66), Mat.STEEL, 2.0)
	_grain(Rect2(440, 94, 120, 66), Mat.STEEL, false, 7)
	draw_line(Vector2(448, 104), Vector2(552, 104), Mat.STEEL_DK, 4.0)
	# sink
	_fill(Rect2(560, 94, 100, 66), Mat.STEEL_DK, 2.0)
	_fill(Rect2(566, 100, 42, 54), Mat.shade(Mat.STEEL_DK, 0.86), 4.0)
	_fill(Rect2(612, 100, 42, 54), Mat.shade(Mat.STEEL_DK, 0.86), 4.0)
	draw_circle(Vector2(587, 127), 4.0, Mat.shade(Mat.STEEL_DK, 0.6))
	draw_circle(Vector2(633, 127), 4.0, Mat.shade(Mat.STEEL_DK, 0.6))
	draw_line(Vector2(610, 100), Vector2(610, 116), Mat.STEEL, 5.0)   # faucet
	draw_line(Vector2(610, 116), Vector2(594, 124), Mat.STEEL, 4.0)
	# range
	_fill(Rect2(660, 94, 80, 66), Mat.IRON, 2.0)
	for p in [Vector2(682, 112), Vector2(710, 112), Vector2(682, 140), Vector2(710, 140)]:
		draw_circle(p, 11.0, Mat.IRON_LT)
		draw_arc(p, 8.0, 0, TAU, 22, Mat.shade(Mat.IRON, 0.7), 2.0)
	draw_circle(Vector2(730, 112), 5.0, Mat.IRON_LT)
	draw_circle(Vector2(730, 140), 5.0, Mat.IRON_LT)
	# worktop lip
	_fill(Rect2(312, 152, 428, 8), Mat.BUTCHER)
	_stroke(run, Mat.shade(Mat.OAK_DK, 0.9), 2.0)

	# pantry + base cabinet
	_obj(Rect2(312, 200, 48, 380), Mat.OAK, 2.0)
	_grain(Rect2(312, 200, 48, 380), Mat.OAK, false, 4)
	for y in [200, 295, 390, 485]:
		_stroke(Rect2(316, y + 5, 40, 85), Mat.OAK_DK, 1.5, 3.0)
		draw_circle(Vector2(350, y + 47), 3.5, Mat.BRASS)
	_obj(Rect2(360, 490, 90, 90), Mat.CAB, 2.0)
	_stroke(Rect2(366, 496, 78, 78), Mat.CAB_DK, 1.5, 3.0)
	draw_circle(Vector2(436, 535), 3.5, Mat.BRASS)

	# dining table with chairs
	for cx in [497, 575, 653]:
		_obj(Rect2(cx - 26, 222, 52, 40), Mat.OAK_DK, 6.0)
		_obj(Rect2(cx - 26, 368, 52, 40), Mat.OAK_DK, 6.0)
	var tbl := Rect2(460, 262, 230, 106)
	_obj(tbl, Mat.BUTCHER, 5.0)
	_grain(tbl, Mat.BUTCHER, true, 7)
	_stroke(tbl.grow(-9.0), Mat.BUTCHER_LN, 1.5, 4.0)

	# sideboard
	_obj(Rect2(740, 530, 130, 70), Mat.OAK, 3.0)
	_grain(Rect2(740, 530, 130, 70), Mat.OAK, true, 4)
	_stroke(Rect2(747, 537, 55, 56), Mat.OAK_DK, 1.5, 3.0)
	_stroke(Rect2(808, 537, 55, 56), Mat.OAK_DK, 1.5, 3.0)


# ── Bathroom ─────────────────────────────────────────────────────────────
func _bathroom() -> void:
	# The sink: the one basin in the house, and the only place the chemicals
	# can be mixed, so it is drawn to be found.
	_obj(Rect2(958, 88, 64, 60), Mat.OAK, 3.0)          # vanity unit
	_fill(Rect2(958, 88, 64, 54), Mat.PORCELAIN, 4.0)   # counter
	_fill(Rect2(958, 88, 64, 9), Mat.PORC_SH, 3.0)      # splashback
	_oval(Vector2(990, 119), 25, 19, Mat.shade(Mat.PORC_SH, 0.97))
	_oval(Vector2(990, 119), 20, 15, Mat.GLASS)         # standing water
	draw_arc(Vector2(990, 119), 20.0, PI * 0.55, PI * 1.25, 18,
		Color(1, 1, 1, 0.55), 2.0)                      # shine on the water
	draw_circle(Vector2(990, 119), 3.5, Mat.STEEL_DK)   # drain
	draw_line(Vector2(990, 92), Vector2(990, 106), Mat.STEEL, 6.0)   # spout
	draw_line(Vector2(990, 106), Vector2(990, 110), Mat.STEEL_DK, 4.0)
	for tap in [Vector2(974, 95), Vector2(1006, 95)]:
		draw_circle(tap, 5.0, Mat.STEEL)
		draw_line(tap - Vector2(4, 0), tap + Vector2(4, 0), Mat.STEEL_DK, 2.0)
	_stroke(Rect2(958, 88, 64, 54), Mat.shade(Mat.PORC_SH, 0.7), 2.0, 4.0)

	_obj(Rect2(1112, 166, 46, 20), Mat.PORCELAIN, 4.0)  # cistern
	_oval(Vector2(1135, 152), 20, 23, Mat.PORCELAIN)    # pan
	_oval(Vector2(1135, 152), 13, 15, Mat.PORC_SH)
	_obj(Rect2(1082, 166, 22, 15), Mat.PORCELAIN, 3.0)  # roll holder

	var sh := Rect2(1185, 95, 85, 85)                   # shower
	_fill(sh, Mat.shade(Mat.CERAMIC, 0.95), 2.0)
	for i in 4:
		draw_line(Vector2(sh.position.x, sh.position.y + 21.0 * i),
			Vector2(sh.end.x, sh.position.y + 21.0 * i), Mat.CERAMIC_LN, 1.5)
		draw_line(Vector2(sh.position.x + 21.0 * i, sh.position.y),
			Vector2(sh.position.x + 21.0 * i, sh.end.y), Mat.CERAMIC_LN, 1.5)
	draw_circle(Vector2(1204, 114), 7.0, Mat.STEEL_DK)
	draw_circle(Vector2(1204, 114), 4.0, Mat.shade(Mat.STEEL_DK, 0.7))
	_fill(Rect2(1185, 172, 85, 8), Mat.GLASS)           # glass screen
	_stroke(sh, Mat.STEEL_DK, 2.5)


# ── Bedroom ──────────────────────────────────────────────────────────────
func _bedroom() -> void:
	_obj(Rect2(944, 450, 300, 122), Mat.RUG, 3.0)       # rug under bed
	_stroke(Rect2(954, 460, 280, 102), Mat.RUG_ALT, 3.0)

	_obj(Rect2(920, 435, 180, 143), Mat.OAK_DK, 4.0)    # bed frame
	_fill(Rect2(920, 435, 26, 143), Mat.WALNUT, 4.0)    # headboard
	_grain(Rect2(920, 435, 26, 143), Mat.WALNUT, false, 3)
	_obj(Rect2(950, 441, 146, 131), Mat.LINEN, 4.0)     # mattress + duvet
	_fill(Rect2(1020, 441, 76, 131), Mat.LINEN_DK, 4.0)
	draw_line(Vector2(1020, 445), Vector2(1020, 568), Mat.shade(Mat.LINEN_DK, 0.85), 2.0)
	_obj(Rect2(1062, 441, 34, 131), Mat.FABRIC, 4.0)    # folded throw
	_cushion(Rect2(954, 446, 44, 58), Mat.PORCELAIN)    # pillows
	_cushion(Rect2(954, 510, 44, 58), Mat.PORCELAIN)

	_obj(Rect2(1196, 552, 42, 26), Mat.OAK, 3.0)        # nightstand
	draw_circle(Vector2(1217, 565), 7.0, Mat.LINEN)     # lamp
	draw_circle(Vector2(1217, 565), 3.0, Mat.BRASS)

	_obj(Rect2(1332, 262, 74, 66), Mat.FABRIC_DK, 10.0) # armchair
	_cushion(Rect2(1340, 270, 44, 50), Mat.FABRIC)
	_oval(Vector2(1282, 268), 32, 32, Mat.FABRIC)       # pouf
	draw_arc(Vector2(1282, 268), 21.0, 0, TAU, 28, Mat.FABRIC_DK, 2.0)


# ── Living room ──────────────────────────────────────────────────────────
func _living() -> void:
	var rug := Rect2(846, 706, 300, 158)                # rug
	_obj(rug, Mat.RUG, 3.0)
	_stroke(rug.grow(-10.0), Mat.RUG_ALT, 3.0)
	for i in 5:
		draw_line(Vector2(rug.position.x + 20.0 + i * 65.0, rug.position.y + 14),
			Vector2(rug.position.x + 20.0 + i * 65.0, rug.end.y - 14),
			Mat.shade(Mat.RUG, 1.12), 2.0)

	var back := Rect2(830, 617, 370, 83)                # sofa back
	_obj(back, Mat.FABRIC_DK, 8.0)
	_cushion(Rect2(838, 623, 148, 71), Mat.FABRIC)
	_cushion(Rect2(994, 623, 92, 71), Mat.FABRIC)
	_cushion(Rect2(1094, 623, 98, 71), Mat.FABRIC)
	var arm := Rect2(1140, 700, 60, 140)                # chaise
	_obj(arm, Mat.FABRIC_DK, 8.0)
	_cushion(Rect2(1146, 708, 48, 60), Mat.FABRIC)
	_cushion(Rect2(1146, 774, 48, 58), Mat.FABRIC)

	var tbl := Rect2(920, 745, 140, 55)                 # coffee table
	_obj(tbl, Mat.WALNUT, 4.0)
	_grain(tbl, Mat.WALNUT, true, 4)
	var desk := Rect2(700, 640, 120, 48)                # writing desk
	_obj(desk, Mat.OAK_DK, 3.0)
	_grain(desk, Mat.OAK_DK, true, 4)
	_fill(Rect2(706, 646, 60, 36), Mat.shade(Mat.OAK_DK, 1.15), 2.0)   # blotter
	_stroke(Rect2(772, 646, 42, 36), Mat.OAK, 1.5, 2.0)                # drawer
	draw_circle(Vector2(793, 664), 3.0, Mat.BRASS)

	_obj(Rect2(1413, 617, 147, 43), Mat.OAK, 3.0)       # sideboard
	_stroke(Rect2(1419, 623, 64, 31), Mat.OAK_DK, 1.5, 3.0)
	_stroke(Rect2(1491, 623, 64, 31), Mat.OAK_DK, 1.5, 3.0)

	_obj(Rect2(1436, 930, 60, 34), Mat.OAK_DK, 4.0)     # doormat at entrance
	for i in 4:
		draw_line(Vector2(1444.0 + i * 13.0, 934), Vector2(1444.0 + i * 13.0, 960),
			Mat.shade(Mat.OAK_DK, 1.2), 2.0)

	_oval(Vector2(1580, 700), 20, 20, Mat.OAK_DK)       # potted plant
	draw_circle(Vector2(1580, 694), 17.0, Mat.LEAF)
	draw_circle(Vector2(1568, 704), 11.0, Mat.shade(Mat.LEAF, 1.15))
	draw_circle(Vector2(1592, 704), 11.0, Mat.shade(Mat.LEAF, 0.9))


# ── Store room / utility ─────────────────────────────────────────────────
func _store() -> void:
	_obj(Rect2(102, 452, 98, 38), Mat.BUTCHER, 2.0)     # workbench
	_grain(Rect2(102, 452, 98, 38), Mat.BUTCHER, true, 3)
	draw_circle(Vector2(160, 484), 4.0, Mat.BRASS)

	var stove := Rect2(206, 926, 98, 52)                # cast-iron wood stove
	_obj(stove, Mat.IRON, 5.0)
	_fill(Rect2(222, 936, 66, 34), Mat.IRON_LT, 4.0)
	_fill(Rect2(228, 941, 54, 24), Mat.EMBER, 3.0)      # firebox glow
	_fill(Rect2(234, 947, 42, 14), Color("f6c26b"), 3.0)
	draw_circle(Vector2(255, 976), 5.0, Mat.STEEL_DK)   # handle
	draw_arc(Vector2(255, 952), 46.0, PI * 1.15, PI * 1.85, 24, Color(1, 0.75, 0.35, 0.16), 30.0)

	var logs := Rect2(115, 890, 78, 88)                 # firewood stack
	_obj(logs, Mat.OAK_DK, 2.0)
	for row in 3:
		for col in 2:
			var c := Vector2(133.0 + col * 40.0, 906.0 + row * 30.0)
			draw_circle(c, 15.0, Mat.OAK)
			draw_circle(c, 9.0, Mat.shade(Mat.OAK, 0.82))
			draw_arc(c, 15.0, 0, TAU, 20, Mat.WALNUT, 1.5)
