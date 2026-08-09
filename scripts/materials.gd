class_name Mat
extends RefCounted

# Shared material palette and drawing primitives for the cabin.

# ── Structure ────────────────────────────────────────────────────────────
const WALL       := Color("7a5c3d")
const WALL_EDGE  := Color("422e1c")
const WALL_GRAIN := Color("8b6c49")

# ── Floors ───────────────────────────────────────────────────────────────
const WOOD       := Color("b07d47")
const WOOD_LINE  := Color("875f34")
const STONE      := Color("b3ab98")
const STONE_LINE := Color("98907c")
const CERAMIC    := Color("d5dbd9")
const CERAMIC_LN := Color("b6bfbc")

# ── Furniture materials ──────────────────────────────────────────────────
const BUTCHER    := Color("c69c63")
const BUTCHER_LN := Color("a37b45")
const OAK        := Color("9c6f43")
const OAK_DK     := Color("6d4a2c")
const WALNUT     := Color("5d3f28")
const CAB        := Color("8c9a84")   # painted cabinet doors
const CAB_DK     := Color("6f7c68")
const STEEL      := Color("c3c8cc")
const STEEL_DK   := Color("979ea4")
const IRON       := Color("2c2c31")
const IRON_LT    := Color("46464e")
const PORCELAIN  := Color("f2f5f4")
const PORC_SH    := Color("dde3e1")
const LINEN      := Color("e9e0cd")
const LINEN_DK   := Color("d0c4a8")
const FABRIC     := Color("8d9585")
const FABRIC_DK  := Color("757d6d")
const RUG        := Color("8a5442")
const RUG_ALT    := Color("b18a63")
const GLASS      := Color("cfe0e4")
const EMBER      := Color("e2853a")
const CARPET     := Color("6f6a63")   # contract carpet, office grey
const LEAF       := Color("5a7d4a")
const BRASS      := Color("c9a227")
const SHADOW     := Color(0, 0, 0, 0.13)


# ── Primitives ───────────────────────────────────────────────────────────
static func rr(r: Rect2, rad: float) -> PackedVector2Array:
	var d: float = min(rad, min(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.end.x - d, r.position.y + d), -PI * 0.5, 0.0],
		[Vector2(r.end.x - d, r.end.y - d), 0.0, PI * 0.5],
		[Vector2(r.position.x + d, r.end.y - d), PI * 0.5, PI],
		[Vector2(r.position.x + d, r.position.y + d), PI, PI * 1.5],
	]
	for c in corners:
		for i in 5:
			var a: float = lerp(c[1], c[2], i / 4.0)
			pts.append(c[0] + Vector2(cos(a), sin(a)) * d)
	return pts


static func shade(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)


# Deterministic 0..1 noise so the plan looks identical on every run.
static func noise(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
