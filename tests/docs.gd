extends Node2D

# Nothing you can read may run off the bottom of the reader. The panel grows
# to what it is holding and steps the type down when it has to, but a long
# enough document would still overrun both.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("hud")
	var fails := 0

	var docs := {}
	for id in Content.ITEMS:
		docs[Content.ITEMS[id]["name"]] = Content.ITEMS[id]["body"]
	for n in Content.FIXED_NOTES:
		docs[n["title"]] = n["body"]
	Game.set_flag("found_body")
	for id in Content.ITEMS:
		Game.inventory.append(id)
	docs["Field report"] = Game.report()

	for title in docs:
		hud._body = docs[title]
		var over: float = hud.reader_overflow()
		if over > 0.0:
			print("FAIL  \"%s\" runs %d px off the page" % [title, over])
			fails += 1

	print("DOCS: %s" % ("ALL PASS" if fails == 0 else "%d OVERFLOW" % fails))
	get_tree().quit()
