extends Node2D

# Doses are written into the notes between *stars* and come out of the
# notebook bold and underlined. The stars themselves must never reach the
# page, the punctuation around a dose must stay stuck to it, and a note
# whose stars do not pair up would embolden everything after it.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	# every note the game can write, including the two it works out itself
	for id in Content.ITEMS:
		var note: String = Content.ITEMS[id].get("note", "")
		if note != "":
			Game.add_note(note)
	Game.inventory.append_array(["norust", "bleach", "exfluid"])
	for part in Game.FORMULA_PARTS:
		Game.set_flag(part)
	Game.mix({"norust": 2.0, "bleach": 1.0, "exfluid": 2.5, "water": 0.0})

	var doses := 0
	for n in Game.notes:
		if n.count("*") % 2 != 0:
			print("FAIL  a note has an odd number of stars in it: %s" % n)
			fails += 1
		for run in hud._note_runs(n):
			var word: String = run[0]
			var strong: bool = run[1]
			var spaced: bool = run[2]
			if word.contains("*"):
				print("FAIL  a star reached the page: %s" % word)
				fails += 1
			if strong:
				doses += 1
			# punctuation left over from a dose must stay against the word it
			# belongs to, or it drifts off on its own or starts a line. An em
			# dash stands on its own with spaces either side and is not that.
			if word in [",", ".", ":", ";"] and spaced:
				print("FAIL  loose punctuation in: %s" % n)
				fails += 1

	fails += _expect("the doses are marked up at all", doses >= 8)

	# the full formula is the note you come back for: all four measures picked
	var formula := ""
	for n in Game.notes:
		if n.begins_with("Full formula"):
			formula = n
	fails += _expect("the formula gets written down", formula != "")
	# four measures, each picked out as one run rather than word by word
	var groups := 0
	var was := false
	for run in hud._note_runs(formula):
		if run[1] and not was:
			groups += 1
		was = run[1]
	fails += _expect("all four measures in it are picked out", groups == 4)

	# and a marked-up note is no taller on the page than the same words plain
	var f := ThemeDB.fallback_font
	var wide := 700.0
	var marked: float = hud._note_flow(f, Vector2.ZERO, formula, wide, 18,
		Color.WHITE, false)
	var plain: float = hud._note_flow(f, Vector2.ZERO,
		formula.replace("*", ""), wide, 18, Color.WHITE, false)
	fails += _expect("marking it up does not change how it wraps",
		absf(marked - plain) < 1.0)
	fails += _expect("and it wraps at all", marked > f.get_height(18) * 1.5)

	print("EMPHASIS: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit()


func _expect(what: String, ok: bool) -> int:
	if ok:
		return 0
	print("FAIL  %s" % what)
	return 1
