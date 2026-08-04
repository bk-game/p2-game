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
		"body": "9/10 — A sapling started growing in my house. It must have clung "
			+ "to my clothes after cutting down some trees. I tried to remove it, but "
			+ "it seems quite stuck. It is pretty small though, so I don't notice it much.\n\n"
			+ "9/13 — The tree has already grown to the roof. What did they do to these "
			+ "trees? I am going to try to cut it down again using my axe. Hopefully this works.",
		"note": "Joe Wood lived here. Something started growing indoors on 9/10.",
	},
	"log_3": {
		"name": "Logbook (page 3)", "kind": "doc", "glyph": "paper",
		"tint": "c8b78d", "pos": Vector2(566, 690), "story": true,
		"body": "9/14 — The tree is regrowing, cutting it down isn't working well. And "
			+ "its network of roots is too dense for me to cut through. But there are some "
			+ "weaker parts of the tree. The weaker parts appear to be a LIGHTER SHADE OF "
			+ "BROWN. These weaker parts can still be cut, just remember they'll regrow in "
			+ "a day or so.\n\n9/15 — I'm going to try to put water on it. Let's hope this "
			+ "goes well.",
		"note": "Pale brown limbs are weak enough to cut through by hand.",
		"grants": "knows_weak",
	},
	"log_formula": {
		"name": "Logbook (page 4, torn)", "kind": "doc", "glyph": "paper",
		"tint": "bfae84", "pos": Vector2(824, 214), "story": true,
		"body": "9/18 — I've been experimenting with different chemicals, I think I've "
			+ "found the correct formula to weaken the tree. In case I forget it's: two "
			+ "cups of NO RUST BUILDUP, one cup of BLEACH, and two and a half cups of the "
			+ "stuff inside the FIRE EXTINGUISHER.\n\n"
			+ "  [ the rest of this page has been torn away ]",
		"note": "Formula: 2 no-rust, 1 bleach, 2.5 extinguisher fluid. Page is torn.",
		"grants": "knows_formula",
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
		"body": "9/19 — The formula has been working, but I think something is wrong with "
			+ "me. My skin has a greenish tint to it now and I find myself slacking on the "
			+ "job.\n\n9/20 — I think the tree's killing me, I'm not sure if this log will "
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
		"body": "Dear Joe Wood,\n\nI am a doctor at the ER. I am sorry to inform you that "
			+ "your husband, Christopher, and your daughter, Eleanor, arrived here after a "
			+ "terrible car accident. Someone ran a red light and T-boned the car. We did "
			+ "our best, but we couldn't save them. I am so sorry for your loss.\n\n"
			+ "A payment of $60,000 has been charged to your card because of the medical "
			+ "resources we used in our attempt to save them. I hope you do well.\n\n— Dr. Neal",
		"note": "The hospital billed him $60,000 for failing to save his family.",
	},
	"death_certs": {
		"name": "Death certificates", "kind": "doc", "glyph": "paper",
		"tint": "e6e2d2", "pos": Vector2(146, 158), "story": true,
		"body": "Two certificates, kept flat and clean in a folder.\n\n"
			+ "CHRISTOPHER WOOD.\nELEANOR WOOD.\n\nSame date on both.",
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
	"bunny": {
		"name": "Stuffed bunny", "kind": "doc", "glyph": "toy",
		"tint": "d9b9c4", "pos": Vector2(310, 880), "story": true,
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
	},
	"extinguisher": {
		"name": "Fire extinguisher", "kind": "tool", "glyph": "extinguisher",
		"tint": "b13a2c", "pos": Vector2(1588, 862),
		"body": "A dry-powder extinguisher, most of a charge left. Heavy enough to "
			+ "clear a room of bad air, if you point it right.",
		"note": "",
	},
	"gasmask": {
		"name": "Gas mask", "kind": "tool", "glyph": "mask",
		"tint": "4c5a4a", "pos": Vector2(150, 340),
		"body": "An industrial respirator with fresh cartridges, hanging on a nail. "
			+ "Joe knew exactly what the air in here was doing to him.",
		"note": "He had a respirator hidden away. He knew the fumes were poison.",
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

# Mixing bench (Joe's workbench in the utility room)
const BENCH := Vector2(150, 522)

# Branches radiating from the tree. strong = needs the brittle solution.
# {pos, len, thick, deg, strong}
const BRANCHES := [
	# ── gates: only these need the brittle solution ──────────────────────
	{"pos": Vector2(242, 460), "len": 110, "thick": 40, "deg": 90,  "strong": true},
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
	{"pos": Vector2(990, 166), "items": ["bleach"]},
	{"pos": Vector2(1486, 692), "items": ["exfluid"]},
	{"pos": Vector2(806, 504), "items": ["log_water"]},
	{"pos": Vector2(1218, 528), "items": ["police_report"]},
	{"pos": Vector2(150, 516), "items": ["axe"]},
	{"pos": Vector2(500, 186), "items": []},
	{"pos": Vector2(610, 186), "items": []},
	{"pos": Vector2(700, 186), "items": []},
	{"pos": Vector2(408, 462), "items": []},
	{"pos": Vector2(1120, 506), "items": []},
	{"pos": Vector2(1306, 306), "items": []},
	{"pos": Vector2(1014, 722), "items": []},
	{"pos": Vector2(992, 822), "items": []},
	{"pos": Vector2(262, 894), "items": []},
	{"pos": Vector2(170, 852), "items": []},
	{"pos": Vector2(1170, 118), "items": []},
	{"pos": Vector2(1540, 700), "items": []},
	{"pos": Vector2(214, 306), "items": []},
]

# Toxic fume clouds. Entering without the mask forces you back to the door.
const FUMES := [
	{"pos": Vector2(392, 866), "r": 122.0},
	{"pos": Vector2(576, 900), "r": 104.0},
	{"pos": Vector2(188, 700), "r": 100.0},
]

const BODY_POS := Vector2(310, 880)
const ENTRANCE := Vector2(1462, 935)
