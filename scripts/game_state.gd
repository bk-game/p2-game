extends Node

# Autoloaded as `Game`. Owns the inventory, what the investigator has learned,
# and the mixed solution.

signal inventory_changed
signal notice(title: String, body: String)
signal toast(text: String)
signal notes_changed
signal open_bench

var inventory: Array[String] = []
var notes: Array[String] = []
var flags := {}

var solution_charges := 0
var extinguisher_charges := 2


func has_item(id: String) -> bool:
	return inventory.has(id)


func add_item(id: String) -> void:
	if inventory.has(id):
		return
	inventory.append(id)
	var it: Dictionary = Content.ITEMS[id]
	if it.get("grants", "") != "":
		set_flag(it["grants"])
	if it.get("note", "") != "":
		add_note(it["note"])
	inventory_changed.emit()
	notice.emit(it["name"], it["body"])


func drop_item(id: String) -> void:
	inventory.erase(id)
	inventory_changed.emit()


func add_note(text: String) -> void:
	if not notes.has(text):
		notes.append(text)
		notes_changed.emit()


func set_flag(f: String, v := true) -> void:
	flags[f] = v


func flag(f: String) -> bool:
	return flags.get(f, false)


# ── Mixing ───────────────────────────────────────────────────────────────
# cups: {chem_id: float}. Returns a player-facing result string.
func mix(cups: Dictionary) -> String:
	for id in Content.FORMULA:
		if not has_item(id) and cups.get(id, 0.0) > 0.0:
			return "You do not have any %s." % Content.ITEMS[id]["name"]
	var total := 0.0
	for id in cups:
		total += cups[id]
	if total <= 0.0:
		return "You need to actually put something in the jar."

	if cups.get("water", 0.0) > 0.0:
		Sfx.play("mix_bad", -6.0)
		add_note("Adding water to the mixture makes the tree grow faster, not slower.")
		return "The mixture goes warm and green, and the shoots on the bench visibly " \
			+ "lengthen. Water feeds it. Tip it out and start again."

	for id in Content.FORMULA:
		if not is_equal_approx(cups.get(id, 0.0), Content.FORMULA[id]):
			Sfx.play("mix_bad", -6.0)
			return "The mixture curdles into a grey sludge and does nothing. " \
				+ "The proportions must be wrong."

	solution_charges += 3
	Sfx.play("mix_ok", -5.0)
	set_flag("made_solution")
	add_note("Two no-rust, one bleach, two and a half extinguisher fluid, no water — "
		+ "this is what weakens the tree.")
	return "The jar clears to a thin amber liquid that smells like a swimming pool. " \
		+ "Three doses. Pour it on a dark limb to make it brittle."


# ── Scoring ──────────────────────────────────────────────────────────────
func story_total() -> int:
	var n := 0
	for id in Content.ITEMS:
		if Content.ITEMS[id].get("story", false):
			n += 1
	return n


func story_found() -> int:
	var n := 0
	for id in inventory:
		if Content.ITEMS[id].get("story", false):
			n += 1
	return n


func report() -> String:
	var found := story_found()
	var total := story_total()
	var pay := found * 250
	var s := "FIELD REPORT — SUBJECT: JOE WOOD\n\n"
	s += "Recovered %d of %d significant items.\n" % [found, total]
	if has_item("bunny"):
		s += "Body located and identified.\n"
	else:
		s += "Body NOT recovered.\n"
	s += "\nAssessed payment: $%d\n\n" % pay
	if found >= total:
		s += "Handler: \"Complete. We can build him properly. Whatever you did in "
		s += "there, do it again next time.\""
	elif found >= total * 0.6:
		s += "Handler: \"Enough to work with. Gaps in the middle of his life, though. "
		s += "He'll come out a little thin.\""
	else:
		s += "Handler: \"This is barely a person. Half of him is missing and we cannot "
		s += "invent the rest.\""
	return s
