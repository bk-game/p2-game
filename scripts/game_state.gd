extends Node

# Autoloaded as `Game`. Owns the inventory, what the investigator has learned,
# and the mixed solution.

signal inventory_changed
signal notice(title: String, body: String)
signal toast(text: String)
signal notes_changed
signal open_sink
signal open_lock
signal open_cut
signal ride(outbound: bool)
signal open_choice(data: Dictionary)
signal level_over
signal acted
signal thought(line: String)
signal lock_opened

var inventory: Array[String] = []
var notes: Array[String] = []
var flags := {}

# Which rooms have their light on, keyed by index into Light.ROOMS. Only the
# rooms with a switch are in here; everywhere else is lit as it always was.
var room_lights := {}

var solution_charges := 0
var cut_bound := false        # the blade, stuck in the doorframe limb
var cut_binds := 0            # how many times it has been stuck in there
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
var _breathed := false


func fog_touch() -> void:
	_fog_touched = true


func fog_ratio() -> float:
	return fog / FOG_LIMIT


func _process(delta: float) -> void:
	if _fog_touched:
		if fog <= 0.0:
			Sfx.play("choke", -14.0, 1.4)
			think("gas")
		fog += delta
		if fog >= FOG_LIMIT:
			_choke_out()
	else:
		if fog > 0.5:
			_breathed = true
		fog = maxf(fog - delta * FOG_CLEAR, 0.0)
		if fog <= 0.0 and _breathed:
			_breathed = false
			think("gas_out")
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


func room_lit(room: int) -> bool:
	return room_lights.get(room, false)


func toggle_room_light(room: int) -> void:
	var on := not room_lit(room)
	room_lights[room] = on
	Sfx.play("open" if on else "empty", -12.0, 1.6)
	toast.emit("The light comes on." if on else "The light goes out.")


# The two places are the same world with a long way between them, so going
# from one to the other is a step through a door and a hard cut.
func travel(to: Vector2) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null:
		p.global_position = to
	fog = 0.0
	Sfx.play("open", -8.0)
	# the office floor is quiet; the music belongs to the job
	if to == Content.OFFICE_START:
		Music.stop()
	else:
		Music.play()


# Going out to the job or coming back from it is a drive, not a step: the
# world is moved under the curtain and the journey plays over the top.
func begin_ride(to: Vector2, outbound: bool) -> void:
	travel(to)
	ride.emit(outbound)


# Back on the floor with the job closed behind you.
func finish_level() -> void:
	if flag("level_done"):
		return
	set_flag("level_done")
	Music.stop()
	Sfx.play("open", -6.0)
	level_over.emit()


# ── The key box ──────────────────────────────────────────────────────────
# One key off the hooks at a time: taking another puts the last one back.
func held_key() -> String:
	for k in Content.KEYS:
		if has_item(k["id"]):
			return k["id"]
	return ""


func take_key(which: int) -> void:
	var id: String = Content.KEYS[which]["id"]
	var had := held_key()
	if had == id:
		toast.emit("That one is already on you.")
		return
	if had != "":
		inventory.erase(had)
	inventory.append(id)
	inventory_changed.emit()
	Sfx.play("pickup", -8.0)
	toast.emit("%s off the hook.%s" % [Content.ITEMS[id]["name"],
		"" if had == "" else " %s back on it." % Content.ITEMS[had]["name"]])
	


# Right key, turned in the right thing, or it does not go.
func try_lock(which: int) -> bool:
	if held_key() != Content.VAN_KEY:
		Sfx.play("empty", -10.0)
		toast.emit("The key goes in and stops. This is not the right key.")
		return false
	if which != Content.VAN_LOCK:
		Sfx.play("empty", -10.0)
		toast.emit("It turns a little and stops. This lock is seized.")
		return false
	Sfx.play("open", -7.0)
	set_flag("signed_out")
	return true


# ── Talking to yourself ──────────────────────────────────────────────────
# Each trigger has a few lines; the ones that fit what you know and what you
# are carrying are used in turn, and none is used twice.
var _said := {}


func think(what: String) -> void:
	if not Content.THOUGHTS.has(what):
		return
	var fits := []
	for line in Content.THOUGHTS[what]:
		if line.get("needs", "") != "" and not flag(line["needs"]):
			continue
		if line.get("not", "") != "" and flag(line["not"]):
			continue
		if line.get("has", "") != "" and not has_item(line["has"]):
			continue
		if line.get("hasnt", "") != "" and has_item(line["hasnt"]):
			continue
		if not _said.has(line["say"]):
			fits.append(line["say"])
	if fits.is_empty():
		return
	_said[fits[0]] = true
	thought.emit(fits[0])


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
	think(id)
	if it.get("story", false) and it.get("note", "") != "":
		think("clue")
	_check_done()


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
	_check_done()


# What you were sent for: the body found, and the certificates in hand. Once
# both are true there is nothing else you need and you can go back.
func _check_done() -> void:
	if flag("can_leave"):
		return
	if not flag("found_body") or not has_item("death_certs"):
		return
	set_flag("can_leave")
	add_note("Body found and identified, certificates recovered. Nothing else "
		+ "here is worth the trip back. Out the way you came in.")
	notice.emit("That is the job", "You have what they sent you for: him, and the "
		+ "paper that says who he was and who he lost.\n\nThere is nothing else in "
		+ "this house that the office will pay for.\n\nThe way out is the door you "
		+ "came in by.")


func _check_formula() -> void:
	if flag("knows_formula"):
		return
	for part in FORMULA_PARTS:
		if not flag(part):
			return
	flags["knows_formula"] = true     # set directly: set_flag comes back here
	add_note("Full formula: *two cups* no-rust, *one cup* bleach, "
		+ "*two and a half cups* extinguisher fluid, *no water*.")


func flag(f: String) -> bool:
	return flags.get(f, false)


# ── The lock on the bathroom door ────────────────────────────────────────
# Four digits, and the only thing that opens it is the date Joe kept
# everywhere. Returns whether the code was right.
func try_code(code: String) -> bool:
	if code != Content.LOCK_CODE:
		Sfx.play("empty", -10.0)
		return false
	set_flag("bedroom_open")
	add_note("The dial on their bedroom door takes Christopher's birthday, 15/10.")
	lock_opened.emit()
	return true


# ── Cutting the limb in the doorframe ────────────────────────────────────
# Four marks, taken in the order the grain gives. Get it wrong and the blade
# sticks fast, exactly as the logbook says it will: it has to be worked back
# out of the limb before you get another go, and it goes in deeper every time
# you bind it, so working your way through the orders costs more the further
# into them you get. Reading the page is the cheap way through.
func try_cut(seq: String) -> bool:
	if seq != Content.CUT_ORDER:
		Sfx.play("chop", -12.0, 0.7)
		cut_bound = true
		cut_binds += 1
		toast.emit("The cut binds again, and the blade goes in deeper than last "
			+ "time." if cut_binds > 1
			else "The cut binds and the blade sticks fast in the grain.")
		return false
	set_flag("gate_cut")
	Sfx.play("crack", -8.0)
	add_note("The limb in the doorframe gives up its cuts knot, split, "
		+ "sap seam, pale ring.")
	return true


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
	add_note("*Two* no-rust, *one* bleach, *two and a half* extinguisher fluid, "
		+ "*no water* — this is what weakens the tree. The bottles hold enough to "
		+ "make it again at the sink whenever the doses run out.")
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
