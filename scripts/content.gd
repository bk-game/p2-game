class_name Content
extends RefCounted

# All story content and entity placement for the Joe Wood investigation.
# Kinds: doc | chem | tool | body | bench

const FORMULA := {"norust": 2.0, "bleach": 1.0, "exfluid": 2.5, "water": 0.0}

const ITEMS := {
	# ── Joe's logbook, torn into pieces ──────────────────────────────────
	"log_1_2": {
		"name": "Logbook (pages 1-2)", "kind": "doc", "glyph": "clipboard",
		"tint": "c8b78d", "pos": Vector2(1500, 950), "story": true,
		"body": "10/9 — A sapling started growing in my house. It must have clung "
			+ "to my clothes after cutting down some trees. I tried to remove it, but "
			+ "it seems quite stuck. It is pretty small though, so I don't notice it much.\n\n"
			+ "13/9 — The tree has already grown to the roof. What did they do to these "
			+ "trees? I am going to try to cut it down again using my axe. Hopefully this works.",
		"note": "Joe Wood lived here. Something started growing indoors on 10/9.",
	},
	"log_3": {
		"name": "Logbook (page 3)", "kind": "doc", "glyph": "paper",
		"tint": "c8b78d", "pos": Vector2(566, 690), "story": true,
		"body": "14/9 — The tree is regrowing, cutting it down isn't working well. And "
			+ "its network of roots is too dense for me to cut through. But there are some "
			+ "weaker parts of the tree. The weaker parts appear to be a LIGHTER SHADE OF "
			+ "BROWN. These weaker parts can still be cut, just remember they'll regrow in "
			+ "a day or so.\n\n15/9 — I’m going to try to put water on it. Then maybe" 
			+ " some  other chemicals? I’m running out of ideas.  ",
		"note": "Pale brown limbs are weak enough to cut through by hand.",
		"grants": "knows_weak",
	},
	"log_formula": {
		"name": "Logbook (page 4, torn)", "kind": "doc", "glyph": "paper",
		"tint": "bfae84", "pos": Vector2(824, 214), "story": true,
		"body": "18/9 — I've been experimenting with different chemicals, I think I've "
			+ "found the correct formula to weaken the tree. It takes three things: NO "
			+ "RUST BUILDUP, BLEACH, and the stuff inside the FIRE EXTINGUISHER.\n\n"
			+ "TWO CUPS of the no rust. The other two measures are further down the "
			+ "page, and the last one I gave up on paper and put somewhere I could not "
			+ "lose it.\n\n"
			+ "It wants a basin and a tap running, so not in here. I am not doing "
			+ "this on the kitchen table again.\n\n"
			+ "  [ the rest of this page has been torn away ]",
		"note": "The mix is no-rust, bleach and extinguisher fluid. Two cups of "
			+ "no-rust. Joe made it up somewhere with a basin and a tap, not the "
			+ "kitchen. The other two measures are written down elsewhere.",
		"grants": "knows_dose_norust",
	},
	"log_dregs": {
		"name": "Logbook (page 4, lower half)", "kind": "doc", "glyph": "scrap",
		"tint": "bfae84", "pos": Vector2(1014, 722), "story": true,
		"body": "The bottom half of the torn page, folded twice.\n\n"
			+ "...and ONE CUP of the BLEACH. No more than that — at two it goes cloudy "
			+ "and does nothing at all.\n\n"
			+ "The third measure is the one I kept getting wrong, so it is not on "
			+ "paper any more. I put it through the wall of the room where I first "
			+ "tried this, and I am not going over it again.",
		"note": "One cup of bleach in the mix, no more. The third measure Joe cut "
			+ "into a wall somewhere, in the room where he first tried mixing.",
		"grants": "knows_dose_bleach",
	},
	"log_cut": {
		"name": "Logbook (page 5)", "kind": "doc", "glyph": "paper",
		"tint": "c8b78d", "pos": Vector2(700, 186), "story": true,
		"body": "17/9 — The one growing through the doorframe will not come apart "
			+ "like the others even softened. There are three hearts in it and they "
			+ "let go in an order. Take them wrong and the last cut binds, the blade "
			+ "sticks, and it closes over by morning.\n\n"
			+ "The knot first. Then the split. The pale ring last, and only last — "
			+ "that is the one holding the weight.",
		"note": "A limb grown into a doorframe has three hearts. Cut the knot, then "
			+ "the split, then the pale ring last.",
		"grants": "knows_cut_order",
	},
	"log_water": {
		"name": "Torn scrap", "kind": "doc", "glyph": "scrap",
		"tint": "bfae84", "pos": Vector2(806, 504), "story": true,
		"body": "...MOST IMPORTANTLY, DO NOT PUT WATER IN THE MIX! Water helps the tree "
			+ "regrow faster. Any water that is already in the mix is the max I can give it.",
		"note": "The missing corner of the formula page. Water must NOT go in the mix.",
		"grants": "knows_no_water",
	},
	"log_5_6": {
		"name": "Logbook (final pages)", "kind": "doc", "glyph": "paper",
		"tint": "c8b78d", "pos": Vector2(1000, 300), "story": true,
		"body": "19/9 — The formula has been working, but I think something is wrong with "
			+ "me. My skin has a greenish tint to it now and I find myself slacking on the "
			+ "job.\n\n20/9 — I think the tree's killing me, I'm not sure if this log will "
			+ "help. Maybe it can save people after me though.",
		"note": "Joe knew it was killing him. He kept writing anyway, for whoever came next.",
	},

	# ── Personal effects ────────────────────────────────────────────────
	"family_photos": {
		"name": "Family photos", "kind": "doc", "glyph": "photo",
		"tint": "9a8f7a", "pos": Vector2(150, 580), "story": true,
		"body": "A cluster of frames: Joe, a man about his age, and a little girl. "
			+ "Birthday parties, several years of them. Crayon drawings, signed in a "
			+ "child's hand. A New Year's photo, all three mid-laugh.\n\n"
			+ "Lifting them off the wall, the panelling behind is loose — there is a way "
			+ "through here.",
		"note": "Joe had a husband and a daughter. The photos hid a door.",
		"grants": "found_secret_door",
	},
	"police_report": {
		"name": "Police report", "kind": "doc", "glyph": "paper",
		"tint": "d8d8d4", "pos": Vector2(1218, 528), "story": true,
		"body": "There was a hit and run that killed Christopher and Eleanor Wood. We do "
			+ "not know who the responsible party is. If you have any leads, please call "
			+ "your nearest police station.",
		"note": "Christopher and Eleanor Wood were killed by a hit-and-run driver. Never caught.",
	},
	"letter_doctor": {
		"name": "Letter from the ER", "kind": "doc", "glyph": "letter",
		"tint": "eae4d6", "pos": Vector2(812, 902), "story": true,
		 "body": "I am Dr. Neal, the Emergency Care Physician tasked with treating "
		+ "\nyour husband, Mr. Christopher Wood, and your daughter, Ms. Eleanor Wood at "
		+ "\nthe North Cayus Emergency Room. I am sorry to inform you that even though "
		+ "\nwe used all our resources, they both weren’t able to make it, their injuries "
		+ "\nwere too severe. I have written to express my sorrow at the suddenness of "
		+ "\ntheir deaths."
		+ "\nSincerely,"
		+ "\nDr. Neal"
	},
	"death_certs": {
		"name": "Death certificates", "kind": "doc", "glyph": "paper",
		"tint": "e6e2d2", "pos": Vector2(146, 158), "story": true,
		"body": "Two certificates, kept flat and clean in a folder.\n\n"
			+ "Name: Christopher Wood 
			\nPlace of Death: North Cayus Emergency Room
			\nUsual Residence: 1053 Meadow Lane. 
			\nCity: North Cayus
			\nFull Name of Hospital Institution: North Cayus Emergency Room
			\nAddress: 0001 Emergency Lane
			\nDate of Birth: 15/10/2042
			\nBirthplace: South Cayus
			\nCause of Death: Collapsed lungs and severed arteries
			\nName of Cemetery or Crematory: North Cayus Crematorium
			\nDate: 26/9/2071
			\nDoctor / Examiner: Dr. Neal
			\nDate: 25/9/2071" 
			+ "Name: Eleanor Wood
			\nPlace of Death: North Cayus Emergency Room
			\nUsual Residence: 1053 Meadow Lane. 
			\nCity: North Cayus
			\nFull Name of Hospital Institution: North Cayus Emergency Room
			\nAddress: 0001 Emergency Lane
			\nDate of Birth: 03/05/2061
			\nBirthplace: North Cayus
			\nCause of Death: Severed arteries and a severe concussion
			\nName of Cemetery or Crematory: North Cayus Crematorium
			\nDate: 26/9/2071
			\nDoctor / Examiner: Dr. Neal
			\nDate: 25/9/2071",
		"note": "He kept their death certificates down here, filed and flattened.",
	},
	"marriage_photo": {
		"name": "Marriage photo", "kind": "doc", "glyph": "photo",
		"tint": "b6a98d", "pos": Vector2(232, 246), "story": true,
		"body": "Christopher and Joe, in front of a registry office, confetti in Joe's "
			+ "beard. Someone has written on the back in pencil: 'the best day, and I "
			+ "mean that.'",
		"note": "Joe and Christopher were married. He kept the photo where no one could see it.",
	},
	"card_christopher": {
		"name": "Birthday card, unsent", "kind": "doc", "glyph": "letter",
		"tint": "d8cfc0", "pos": Vector2(1540, 700), "story": true,
		"body": "A card with a boat on the front, written in and never sent.\n\n"
			+ "\"Chris — 15/10 again. Twenty-nine years of me getting you the wrong "
			+ "thing. I have kept the date on everything in this house because it is "
			+ "the only four numbers I will never lose.\n\nAll my love, always. J.\"",
		"note": "Christopher's birthday is 15/10. Joe used the date on things around "
			+ "the house because he could not lose it.",
		"grants": "knows_chris_birthday",
	},
	"card_eleanor": {
		"name": "Child's birthday card", "kind": "doc", "glyph": "photo",
		"tint": "e8c9d4", "pos": Vector2(1306, 306), "story": true,
		"body": "Card stock folded by a child, a cake drawn on it in wax crayon with "
			+ "ten candles counted out carefully.\n\n"
			+ "\"TO ELEANOR. 3/5. LOVE DAD AND DAD.\"\n\n"
			+ "Inside, in an adult hand: \"Ten. How.\"",
		"note": "Eleanor's birthday is 3/5. She turned ten.",
		"grants": "knows_eleanor_birthday",
	},
	"bunny": {
		"name": "Stuffed bunny", "kind": "doc", "glyph": "toy",
		"tint": "d9b9c4", "pos": Vector2(172, 352), "story": true,
		"body": "An old stuffed rabbit, worn thin at the ears from handling. A fabric tag "
			+ "stitched to one foot reads ELEANOR.\n\nJoe's hands are closed around it.",
		"note": "He died holding his daughter's rabbit.",
	},

	# ── Tools ───────────────────────────────────────────────────────────
	"axe": {
		"name": "Joe's axe", "kind": "tool", "glyph": "axe",
		"tint": "8a6440", "pos": Vector2(150, 516),
		"body": "A felling axe, the handle worn smooth. The bit is chipped all along "
			+ "its edge, like it has been swung into something far too hard, many times.",
		"note": "Joe cut at the tree over and over. The axe edge is destroyed.",
		"use": "Blunt past saving. Pale limbs still come apart by hand: hold [E].",
	},
	"extinguisher": {
		"name": "Fire extinguisher", "kind": "tool", "glyph": "extinguisher",
		"tint": "b13a2c", "pos": Vector2(1588, 862),
		"body": "A dry-powder extinguisher, most of a charge left. Heavy enough to "
			+ "clear a room of bad air, if you point it right.",
		"note": "The extinguisher blows a green cloud out of the air. Walk into "
			+ "range of one and press [E].",
		"use": "Stand at a green cloud and press [E] to blow it out of the air.",
	},

	# ── Chemicals ───────────────────────────────────────────────────────
	"norust": {
		"name": "No Rust Buildup", "kind": "chem", "glyph": "bottle",
		"tint": "d8c24a", "pos": Vector2(376, 186),
		"body": "A tall jug of rust remover. Mostly phosphoric acid, by the smell.",
		"note": "",
	},
	"bleach": {
		"name": "Bleach", "kind": "chem", "glyph": "bottle",
		"tint": "e2eef0", "pos": Vector2(990, 166),
		"body": "Household bleach, half gone.",
		"note": "",
	},
	"exfluid": {
		"name": "Extinguisher fluid", "kind": "chem", "glyph": "bottle",
		"tint": "9fc7a8", "pos": Vector2(1486, 692),
		"body": "A decanted bottle of extinguisher agent. Joe must have emptied a "
			+ "spare cylinder into it.",
		"note": "",
	},
	"water": {
		"name": "Water", "kind": "chem", "glyph": "bottle",
		"tint": "7fb6d6", "pos": Vector2(392, 384),
		"body": "A jug of tap water.",
		"note": "",
	},
}

# The bathroom sink. Mixing needs a basin and a tap, so it happens here and
# nowhere else.
const SINK := Vector2(990, 150)

# ── Light switches ───────────────────────────────────────────────────────
# Two rooms are on the house wiring and are pitch dark until you find the
# switch by the door. "room" indexes into Light.ROOMS.
const SWITCHES := [
	{"pos": Vector2(1045, 174), "room": 2},   # bathroom
	{"pos": Vector2(196, 407), "room": 0},    # the room at the back
]

# ── The limb across the door under the tree ──────────────────────────────
# It has grown into the frame and has three hearts in it. Softening it is not
# enough: the cuts have to be taken in the order the grain will give, or the
# last one binds the blade and the whole thing closes up again. The marks are
# what you see on it; Joe worked the order out and wrote it down.
const CUT_MARKS := ["the pale ring", "the black knot", "the split"]
const CUT_ORDER := "231"

# ── The lock on the bedroom ──────────────────────────────────────────────
# Their room, and the way through to the bathroom beyond it. Joe put the date
# on everything in the house because it was four numbers he could not lose:
# Christopher's birthday, 15/10. The card in the living room carries it, and
# so do the death certificates, once you can get to them.
const LOCK_CODE := "1510"
const LOCK_POS := Vector2(1307, 596)
const LOCK_DOOR := Rect2(1272, 578, 70, 37)

# ── Notes fixed in place ─────────────────────────────────────────────────
# Writing that belongs to the house rather than to you: read it where it is,
# it never comes into the bag, and it never counts towards what you
# recovered. "surface" picks how it is drawn — gouged into a wall, or a sheet
# left on a piece of furniture.
const FIXED_NOTES := [
	{
		"pos": Vector2(760, 682), "surface": "desk",
		"prompt": "Read the note on the desk",
		"title": "Note on the desk",
		"body": "Joe's hand, hurried, held down by a mug ring.\n\n"
			+ "\"Two ways out of this room and I only ever use the one. The other you "
			+ "would have to know was there — it has taken that end of the room and I "
			+ "walk straight past it.\n\n"
			+ "Everything I have left is on the far side of it.\"",
		"note": "There is another way out of the living room, and the tree has taken "
			+ "that end of it. What Joe had left is through there.",
		"grants": "knows_back_door",
	},
	{
		"pos": Vector2(540, 598), "surface": "wall",
		"prompt": "Read what is cut into the wall",
		"title": "Cut into the kitchen wall",
		"body": "Low down on the boards by the table, deep, with something sharper "
			+ "than a knife. The letters are gone over twice.\n\n"
			+ "TWO AND A HALF CUPS OF THE EXTINGUISHER STUFF.\n\n"
			+ "Under it, smaller: \"STOP GUESSING. FOUR BATCHES WASTED.\"",
		"note": "Cut into the kitchen wall: two and a half cups of extinguisher fluid.",
		"grants": "knows_dose_exfluid",
	},
]

# Branches radiating from the tree. strong = needs the brittle solution.
# {pos, len, thick, deg, strong}
const BRANCHES := [
	# ── gates: only these need the brittle solution ──────────────────────
	{"pos": Vector2(242, 460), "len": 110, "thick": 40, "deg": 90,  "strong": true},
	{"pos": Vector2(468, 745), "len": 110, "thick": 34, "deg": 90,  "strong": true,
		"gate": true},
	{"pos": Vector2(360, 770), "len": 150, "thick": 30, "deg": 24,  "strong": true},
	{"pos": Vector2(188, 620), "len": 130, "thick": 28, "deg": 96,  "strong": true},
	{"pos": Vector2(180, 200), "len": 140, "thick": 30, "deg": 40,  "strong": true},
	{"pos": Vector2(408, 890), "len": 170, "thick": 32, "deg": 20,  "strong": true},
	{"pos": Vector2(318, 946), "len": 150, "thick": 30, "deg": 108, "strong": true},
	{"pos": Vector2(806, 858), "len": 180, "thick": 32, "deg": 74,  "strong": true},
	# ── the barricade across the front door: cut your way in ────────────
	{"pos": Vector2(1462, 872), "len": 210, "thick": 26, "deg": 0,   "strong": false},
	{"pos": Vector2(1382, 928), "len": 140, "thick": 26, "deg": 62,  "strong": false},
	{"pos": Vector2(1542, 928), "len": 140, "thick": 26, "deg": 118, "strong": false},
	# ── the rest are pale limbs you cut by hand ──────────────────────────
	{"pos": Vector2(470, 806), "len": 210, "thick": 30, "deg": 92,  "strong": false},
	{"pos": Vector2(660, 742), "len": 240, "thick": 28, "deg": 24,  "strong": false},
	{"pos": Vector2(700, 918), "len": 200, "thick": 26, "deg": 156, "strong": false},
	{"pos": Vector2(560, 668), "len": 160, "thick": 26, "deg": 112, "strong": false},
	{"pos": Vector2(636, 596), "len": 150, "thick": 24, "deg": 84,  "strong": false},
	{"pos": Vector2(346, 742), "len": 140, "thick": 26, "deg": 38,  "strong": false},
	{"pos": Vector2(196, 856), "len": 150, "thick": 24, "deg": 12,  "strong": false},
	{"pos": Vector2(160, 640), "len": 130, "thick": 22, "deg": 78,  "strong": false},
	{"pos": Vector2(392, 690), "len": 120, "thick": 22, "deg": 140, "strong": false},
	{"pos": Vector2(900, 800), "len": 210, "thick": 26, "deg": 8,   "strong": false},
	{"pos": Vector2(1050, 906), "len": 190, "thick": 24, "deg": 166, "strong": false},
	{"pos": Vector2(1180, 660), "len": 150, "thick": 22, "deg": 96,  "strong": false},
	{"pos": Vector2(1310, 880), "len": 200, "thick": 26, "deg": 20,  "strong": false},
	{"pos": Vector2(1480, 780), "len": 170, "thick": 24, "deg": 112, "strong": false},
	{"pos": Vector2(1560, 920), "len": 140, "thick": 22, "deg": 40,  "strong": false},
	{"pos": Vector2(560, 470), "len": 190, "thick": 26, "deg": 68,  "strong": false},
	{"pos": Vector2(760, 330), "len": 210, "thick": 24, "deg": 22,  "strong": false},
	{"pos": Vector2(470, 180), "len": 160, "thick": 22, "deg": 130, "strong": false},
	{"pos": Vector2(830, 130), "len": 140, "thick": 20, "deg": 84,  "strong": false},
	{"pos": Vector2(392, 300), "len": 130, "thick": 22, "deg": 16,  "strong": false},
	{"pos": Vector2(1010, 250), "len": 170, "thick": 24, "deg": 44,  "strong": false},
	{"pos": Vector2(1240, 330), "len": 200, "thick": 24, "deg": 158, "strong": false},
	{"pos": Vector2(1360, 480), "len": 150, "thick": 22, "deg": 100, "strong": false},
	{"pos": Vector2(1080, 470), "len": 140, "thick": 20, "deg": 8,   "strong": false},
	{"pos": Vector2(1150, 140), "len": 130, "thick": 20, "deg": 26,  "strong": false},
	{"pos": Vector2(214, 250), "len": 150, "thick": 22, "deg": 74,  "strong": false},
	{"pos": Vector2(186, 130), "len": 120, "thick": 20, "deg": 20,  "strong": false},
]

# Anything you can open. Most hold nothing — you find out by trying.
const CONTAINERS := [
	{"pos": Vector2(376, 186), "items": ["norust"]},
	{"pos": Vector2(392, 384), "items": ["water"]},
	{"pos": Vector2(1170, 118), "items": ["bleach"]},
	{"pos": Vector2(1486, 692), "items": ["exfluid"]},
	{"pos": Vector2(806, 504), "items": ["log_water"]},
	{"pos": Vector2(1218, 528), "items": ["police_report"]},
	{"pos": Vector2(150, 516), "items": ["axe"]},
	{"pos": Vector2(500, 186), "items": []},
	{"pos": Vector2(610, 186), "items": []},
	{"pos": Vector2(700, 186), "items": ["log_cut"]},
	{"pos": Vector2(408, 462), "items": []},
	{"pos": Vector2(1120, 506), "items": []},
	{"pos": Vector2(1306, 306), "items": ["card_eleanor"]},
	{"pos": Vector2(1014, 722), "items": ["log_dregs"]},
	{"pos": Vector2(992, 822), "items": []},
	{"pos": Vector2(262, 894), "items": []},
	{"pos": Vector2(170, 852), "items": []},
	{"pos": Vector2(1540, 700), "items": ["card_christopher"]},
	{"pos": Vector2(214, 306), "items": []},
]

# Toxic fume clouds. Walking into one puts you back on the doorstep, so a
# cloud has to be blown out with the extinguisher before you can pass it.
const FUMES := [
	{"pos": Vector2(576, 900), "r": 104.0},
	# over the hidden door and the hardened limb across it, so the way in to
	# the room at the back is hidden in the green as well as blocked
	{"pos": Vector2(230, 455), "r": 95.0},
]

# The hidden room at the back, behind the panelling the photos covered.
const BODY_POS := Vector2(172, 352)
const ENTRANCE := Vector2(1462, 935)
