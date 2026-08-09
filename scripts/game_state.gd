extends Node

# Autoloaded as `Game`. Owns the inventory, what the investigator has learned,
# and the mixed solution.

signal inventory_changed
signal notice(title: String, body: String)
signal toast(text: String)
signal notes_changed
signal open_sink

var inventory: Array[String] = []
var notes: Array[String] = []
var flags := {}

var solution_charges := 0
var extinguisher_charges := 3

# ── Breathing the green ──────────────────────────────────────────────────
# Standing in a cloud does not throw you out at once: the air turns green
# around you and you have FOG_LIMIT seconds to get back out of it. Every
# cloud you are standing in reports itself each frame and the count is kept
# here, so two overlapping clouds still choke you at one rate.
const FOG_LIMIT := 2.0
const FOG_CLEAR := 0.8   # how fast it washes out again, relative to real time

var fog := 0.0
var _fog_touched := false


func fog_touch() -> void:
	_fog_touched = true


func fog_ratio() -> float:
	return fog / FOG_LIMIT


func _process(delta: float) -> void:
	if _fog_touched:
		if fog <= 0.0:
			Sfx.play("choke", -14.0, 1.4)
			toast.emit("Green air. It burns going in — get out of it.")
		fog += delta
		if fog >= FOG_LIMIT:
			_choke_out()
	else:
		fog = maxf(fog - delta * FOG_CLEAR, 0.0)
	_fog_touched = false


# Out of time: you come to on the doorstep.
func _choke_out() -> void:
	fog = 0.0
	var p := get_tree().get_first_node_in_group("player")
	if p != null:
		p.global_position = Content.ENTRANCE
	Sfx.play("choke", -5.0)
	toast.emit("Your throat closes and everything goes white. You come to on the "
		+ "doorstep. You need clean air to go in there.")


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


# The three measures are written down in three different places, one of them
# on a wall. Holding all three is what counts as knowing the formula.
const FORMULA_PARTS := ["knows_dose_norust", "knows_dose_bleach", "knows_dose_exfluid"]


func set_flag(f: String, v := true) -> void:
	flags[f] = v
	_check_formula()


func _check_formula() -> void:
	if flag("knows_formula"):
		return
	for part in FORMULA_PARTS:
		if not flag(part):
			return
	flags["knows_formula"] = true     # set directly: set_flag comes back here
	add_note("Full formula: two cups no-rust, one cup bleach, two and a half cups "
		+ "extinguisher fluid, no water. Made up in the bathroom sink.")


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
		return "You need to actually pour something into the basin."

	if cups.get("water", 0.0) > 0.0:
		Sfx.play("mix_bad", -6.0)
		add_note("Adding water to the mixture makes the tree grow faster, not slower.")
		return "The mixture goes warm and green, and the shoots around the basin " \
			+ "visibly lengthen. Water feeds it. Rinse it out and start again."

	for id in Content.FORMULA:
		if not is_equal_approx(cups.get(id, 0.0), Content.FORMULA[id]):
			Sfx.play("mix_bad", -6.0)
			return "The mixture curdles into a grey sludge and does nothing. " \
				+ "The proportions must be wrong."

	var again := flag("made_solution")
	solution_charges += 3
	Sfx.play("mix_ok", -5.0)
	set_flag("made_solution")
	add_note("Two no-rust, one bleach, two and a half extinguisher fluid, no water — "
		+ "this is what weakens the tree. The bottles hold enough to make it again "
		+ "at the sink whenever the doses run out.")
	# Nothing is used up but the doses, so the sink can be come back to.
	if again:
		return "Another batch, the same thin amber. Three more doses — %d in hand." \
			% solution_charges
	return "The water in the basin clears to a thin amber liquid that smells like " \
		+ "a swimming pool. Three doses. Pour it on a dark limb to make it brittle. " \
		+ "There is enough in the bottles to mix this again when they run out."


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
	# Finding him is what changes this line. Taking the rabbit out of his
	# hands is a second thing, reported separately.
	if flag("found_body"):
		s += "Body located and identified: Joe Wood.\n"
		if has_item("bunny"):
			s += "Personal effect recovered from his hands.\n"
		else:
			s += "His hands are still closed around something. Left in place.\n"
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
