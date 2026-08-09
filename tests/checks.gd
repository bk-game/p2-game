extends Node2D

func _ready() -> void:
	var fails := 0
	var FP = load("res://scripts/floorplan.gd")

	# 1. every item / station must sit in open space
	var blockers: Array[Rect2] = []
	for w in FP.WALLS:
		var parts: Array = [w]
		for d in FP.DOORS:
			var nxt: Array = []
			for p in parts:
				nxt.append_array(_sub(p, d["rect"]))
			parts = nxt
		for p in parts:
			blockers.append(p)
	for s in FP.SOLIDS:
		blockers.append(s)

	var spots := {}
	for id in Content.ITEMS:
		spots[id] = Content.ITEMS[id]["pos"]
	for i in Content.CONTAINERS.size():
		spots["<container %d>" % i] = Content.CONTAINERS[i]["pos"]
	spots["<body>"] = Content.BODY_POS
	spots["<spawn>"] = Content.ENTRANCE
	for id in spots:
		for b in blockers:
			if b.grow(10.0).has_point(spots[id]):
				print("FAIL  %s at %s is inside geometry %s" % [id, spots[id], b])
				fails += 1
				break

	# 2. mixing
	for c in ["norust", "bleach", "exfluid", "water"]:
		Game.inventory.append(c)
	fails += _expect("water poisons the mix",
		Game.mix({"norust": 2.0, "bleach": 1.0, "exfluid": 2.5, "water": 1.0}).contains("Water feeds it"))
	fails += _expect("no charges yet", Game.solution_charges == 0)
	fails += _expect("wrong ratio rejected",
		Game.mix({"norust": 1.0, "bleach": 1.0, "exfluid": 2.5}).contains("curdles"))
	fails += _expect("still no charges", Game.solution_charges == 0)
	fails += _expect("empty basin rejected", Game.mix({}).contains("actually pour something"))
	fails += _expect("correct formula works",
		Game.mix({"norust": 2.0, "bleach": 1.0, "exfluid": 2.5, "water": 0.0}).contains("amber"))
	fails += _expect("three charges", Game.solution_charges == 3)
	# the sink can be come back to: nothing but the doses is used up
	fails += _expect("mixing again works",
		Game.mix({"norust": 2.0, "bleach": 1.0, "exfluid": 2.5, "water": 0.0})
			.contains("Another batch"))
	fails += _expect("doses stack up", Game.solution_charges == 6)

	# 3. scoring
	fails += _expect("15 story items", Game.story_total() == 15)
	for id in Content.ITEMS:
		if not Game.inventory.has(id):
			Game.inventory.append(id)
	fails += _expect("full score", Game.story_found() == 15)
	# 4. the report's body line has to follow the body
	fails += _expect("body not recovered until you find him",
		Game.report().contains("Body NOT recovered"))
	Game.set_flag("found_body")
	fails += _expect("finding him changes the line",
		Game.report().contains("Body located") and not Game.report().contains("NOT recovered"))
	fails += _expect("rabbit reported separately",
		Game.report().contains("Personal effect recovered"))
	Game.inventory.erase("bunny")
	fails += _expect("rabbit left in place is said so",
		Game.report().contains("still closed around something"))

	print("RESULT: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()

func _expect(what: String, ok: bool) -> int:
	if not ok:
		print("FAIL  ", what)
		return 1
	return 0

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
