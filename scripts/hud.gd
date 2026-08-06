extends Control

# Interaction prompt, document reader, bag with mixing, and notebook.
# Everything is drawn in code onto one Control so there is no theme to wire up.
# All sizes derive from S, so the whole interface rescales from one number.

const S := 1.35

const INK    := Color("f0e9db")
const DIM    := Color("b3a992")
const PANEL  := Color(0.10, 0.09, 0.08, 0.94)
const EDGE   := Color("6d5a3e")
const ACCENT := Color("e0b25c")

enum Mode {PLAY, READ, BAG, NOTES, REPORT}

var mode: int = Mode.PLAY
var _title: String = ""
var _body: String = ""
var _toast: String = ""
var _toast_t: float = 0.0
var _prompt: String = ""
var _cups: Dictionary = {"norust": 0.0, "bleach": 0.0, "exfluid": 0.0, "water": 0.0}
var _sel: int = 0
var _mix_msg: String = ""
var _progress: float = 0.0

# ---- scroll state for bag list ----
var _scroll: int = 0
const ENTRY_HEIGHT := 34.0   # unscaled height of one inventory row

# ---- scroll state for notes ----
var _notes_scroll: int = 0


func _ready() -> void:
	Game.notice.connect(_on_notice)
	Game.toast.connect(_on_toast)
	Game.inventory_changed.connect(func(): queue_redraw())
	Game.notes_changed.connect(func(): queue_redraw())
	Game.open_bench.connect(_open_bench)


func blocking() -> bool:
	return mode != Mode.PLAY


func set_prompt(t: String) -> void:
	if t != _prompt:
		_prompt = t
		queue_redraw()


func set_progress(v: float) -> void:
	if not is_equal_approx(v, _progress):
		_progress = v
		queue_redraw()


func _on_notice(title: String, body: String) -> void:
	_title = title
	_body = body
	mode = Mode.READ
	queue_redraw()


func _on_toast(text: String) -> void:
	_toast = text
	_toast_t = 5.0
	queue_redraw()


func _open_bench() -> void:
	mode = Mode.BAG
	queue_redraw()


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast = ""
		queue_redraw()


# ── sizing helpers ───────────────────────────────────────────────────────
func _n(v: float) -> float:
	return v * S


func _fs(v: int) -> int:
	return int(round(v * S))


# ── bag scroll helper ───────────────────────────────────────────────────
func _get_max_visible() -> int:
	var vp: Vector2 = size
	var r: Rect2 = _centre(vp, 980, 640)
	var list_top: float = r.position.y + _n(122)
	var list_bottom: float = r.end.y - _n(126) - _n(10)   # leave room for footer/separator
	var available: float = list_bottom - list_top
	var entry_h: float = _n(ENTRY_HEIGHT)
	return maxi(1, int(available / entry_h))


# ── notes scroll helper (computes actual note heights) ──────────────────
func _get_max_visible_notes() -> int:
	var vp: Vector2 = size
	var r: Rect2 = _centre(vp, 900, 600)
	var list_top: float = r.position.y + _n(146)
	var list_bottom: float = r.end.y - _n(28) - _n(16)   # leave room for footer
	var available: float = list_bottom - list_top
	var f: Font = ThemeDB.fallback_font
	var max_width: float = r.size.x - _n(104)
	var font_size: int = _fs(18)
	var line_spacing: float = _n(16)
	var y: float = 0.0
	var count: int = 0
	for n in Game.notes:
		var h: float = f.get_multiline_string_size(n, HORIZONTAL_ALIGNMENT_LEFT,
			max_width, font_size).y
		if y + h + line_spacing > available:
			break
		y += h + line_spacing
		count += 1
	return maxi(1, count)


# ══ Input ════════════════════════════════════════════════════════════════
func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var k: int = (e as InputEventKey).keycode
	match mode:
		Mode.READ:
			if k in [KEY_E, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
				mode = Mode.PLAY
		Mode.NOTES:
			if k in [KEY_N, KEY_ESCAPE, KEY_E, KEY_I]:
				mode = Mode.PLAY
			elif k == KEY_UP:
				_notes_scroll = maxi(_notes_scroll - 1, 0)
				queue_redraw()
			elif k == KEY_DOWN:
				var max_scroll: int = maxi(0, Game.notes.size() - _get_max_visible_notes())
				_notes_scroll = mini(_notes_scroll + 1, max_scroll)
				queue_redraw()
		Mode.REPORT:
			if k in [KEY_N, KEY_R, KEY_ESCAPE, KEY_E, KEY_I]:
				mode = Mode.PLAY
		Mode.BAG:
			_bag_key(k)
		Mode.PLAY:
			if k == KEY_I:
				mode = Mode.BAG
				_sel = 0
				_scroll = 0
			elif k == KEY_C:
				var lamp: Node = get_tree().get_first_node_in_group("light")
				if lamp != null:
					lamp.toggle()
			elif k == KEY_N:
				mode = Mode.NOTES
				_notes_scroll = 0   # reset scroll when opening
			elif k == KEY_R:
				_title = "Field report"
				_body = Game.report()
				mode = Mode.REPORT
			else:
				return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _bag_key(k: int) -> void:
	var bag: Array = Game.inventory
	match k:
		KEY_ESCAPE, KEY_Q, KEY_I:
			mode = Mode.PLAY
		KEY_UP:
			if _sel > 0:
				_sel -= 1
				if _sel < _scroll:
					_scroll = _sel
		KEY_DOWN:
			if _sel < bag.size() - 1:
				_sel += 1
				var max_vis: int = _get_max_visible()
				if _sel >= _scroll + max_vis:
					_scroll = _sel - max_vis + 1
		KEY_RIGHT, KEY_LEFT:
			if _sel < bag.size() and _cups.has(bag[_sel]):
				var step: float = 0.5 if k == KEY_RIGHT else -0.5
				_cups[bag[_sel]] = clampf(_cups[bag[_sel]] + step, 0.0, 5.0)
		KEY_ENTER, KEY_E:
			if _sel < bag.size():
				var it: Dictionary = Content.ITEMS[bag[_sel]]
				_title = it["name"]
				_body = it["body"]
				mode = Mode.READ
		KEY_M:
			_mix_msg = Game.mix(_cups)
			if Game.flag("made_solution"):
				for c in _cups:
					_cups[c] = 0.0


# ══ Drawing ══════════════════════════════════════════════════════════════
func _draw() -> void:
	var f: Font = ThemeDB.fallback_font
	var vp: Vector2 = size

	# ── carrying summary; the full list lives in the bag panel ──────────
	var st: Array = ["%d carried  [I]" % Game.inventory.size()]
	if Game.solution_charges > 0:
		st.append("solution x%d" % Game.solution_charges)
	if Game.has_item("extinguisher"):
		st.append("extinguisher x%d" % Game.extinguisher_charges)
	if Game.has_item("gasmask"):
		st.append("mask on")
	var line: String = "   ".join(st)
	var bw: float = f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18)).x + _n(40)
	var bar: Rect2 = Rect2(_n(20), vp.y - _n(70), bw, _n(46))
	_panel(bar)
	draw_string(f, Vector2(bar.position.x + _n(20), bar.position.y + _n(31)), line,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), INK)

	# ── key hints ───────────────────────────────────────────────────────
	var hint: String = "[E] interact   [I] bag   [N] notebook   [C] lantern   [R] report"
	var hw: float = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(15)).x
	draw_string(f, Vector2(vp.x - hw - _n(24), vp.y - _n(28)), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(15), DIM)

	# ── interaction prompt ──────────────────────────────────────────────
	if _prompt != "" and mode == Mode.PLAY:
		var w: float = f.get_string_size(_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(19)).x + _n(64)
		var pr: Rect2 = Rect2(vp.x * 0.5 - w * 0.5, vp.y - _n(140), w, _n(44))
		_panel(pr)
		draw_string(f, Vector2(pr.position.x + _n(20), pr.position.y + _n(30)),
			"E  " + _prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19), INK)
		if _progress > 0.0:
			var track: Rect2 = Rect2(pr.position.x + _n(14), pr.end.y + _n(8),
				pr.size.x - _n(28), _n(10))
			draw_rect(track, Color(0, 0, 0, 0.55))
			draw_rect(Rect2(track.position, Vector2(track.size.x * _progress,
				track.size.y)), ACCENT)
			draw_rect(track, EDGE, false, 2.0)

	# ── toast ───────────────────────────────────────────────────────────
	if _toast != "":
		var tr: Rect2 = Rect2(vp.x * 0.5 - _n(430), _n(26), _n(860), _n(74))
		_panel(tr)
		draw_multiline_string(f, Vector2(tr.position.x + _n(20), tr.position.y + _n(30)),
			_toast, HORIZONTAL_ALIGNMENT_LEFT, tr.size.x - _n(40), _fs(17), 2, INK)

	match mode:
		Mode.READ, Mode.REPORT: _draw_reader(f, vp)
		Mode.NOTES: _draw_notes(f, vp)
		Mode.BAG: _draw_bag(f, vp)


func _draw_reader(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r: Rect2 = _centre(vp, 860, 540)
	_panel(r)
	_head(f, r, _title, "")
	draw_multiline_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(120)),
		_body, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(19), -1, INK)
	_foot(f, r, "[E] put it away")


func _draw_notes(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r: Rect2 = _centre(vp, 900, 600)
	_panel(r)
	_head(f, r, "NOTEBOOK", "%d of %d significant items recovered"
		% [Game.story_found(), Game.story_total()])

	var notes: Array = Game.notes
	if notes.is_empty():
		draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(146)),
			"Nothing written down yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19), DIM)
	else:
		# ---------- scrolling logic ----------
		var total: int = notes.size()
		var max_visible: int = _get_max_visible_notes()
		# Clamp scroll to valid range
		_notes_scroll = clamp(_notes_scroll, 0, total - 1)
		# Ensure scroll never goes out of bounds with max_visible
		_notes_scroll = clamp(_notes_scroll, 0, maxi(0, total - max_visible))

		var y: float = r.position.y + _n(146)
		var start_idx: int = _notes_scroll
		var end_idx: int = min(_notes_scroll + max_visible, total)

		for i in range(start_idx, end_idx):
			var n: String = notes[i]
			var h: float = f.get_multiline_string_size(n, HORIZONTAL_ALIGNMENT_LEFT,
				r.size.x - _n(104), _fs(18)).y
			draw_string(f, Vector2(r.position.x + _n(38), y), "-",
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), ACCENT)
			draw_multiline_string(f, Vector2(r.position.x + _n(62), y), n,
				HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(104), _fs(18), -1, INK)
			y += h + _n(16)

	_foot(f, r, "[N] close   [↑↓] scroll")


func _draw_bag(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r: Rect2 = _centre(vp, 980, 640)
	_panel(r)
	_head(f, r, "BAG", "carrying %d" % Game.inventory.size())

	if Game.inventory.is_empty():
		draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(126)),
			"Empty.", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(20), DIM)
	else:
		# ---------- scrolling logic ----------
		var total: int = Game.inventory.size()
		var max_visible: int = _get_max_visible()
		# Clamp scroll to valid range
		_scroll = clamp(_scroll, 0, total - 1)
		# Keep selected item visible
		if _sel < _scroll:
			_scroll = _sel
		if _sel >= _scroll + max_visible:
			_scroll = _sel - max_visible + 1
		# Ensure scroll never goes out of bounds
		_scroll = clamp(_scroll, 0, maxi(0, total - max_visible))

		var entry_h: float = _n(ENTRY_HEIGHT)
		var y: float = r.position.y + _n(122)
		var start_idx: int = _scroll
		var end_idx: int = min(_scroll + max_visible, total)

		for i in range(start_idx, end_idx):
			var id: String = Game.inventory[i]
			var it: Dictionary = Content.ITEMS[id]

			# highlight selected row
			if i == _sel:
				draw_rect(Rect2(r.position.x + _n(28), y - _n(22), r.size.x - _n(56),
					_n(34)), Color(1, 1, 1, 0.07))
				draw_string(f, Vector2(r.position.x + _n(38), y), ">",
					HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(20), ACCENT)

			# colour swatch
			draw_rect(Rect2(r.position.x + _n(60), y - _n(14), _n(13), _n(18)),
				Color(it["tint"]))

			# item name
			draw_string(f, Vector2(r.position.x + _n(84), y), it["name"],
				HORIZONTAL_ALIGNMENT_LEFT, _n(460), _fs(19), INK)

			# cup amount
			if _cups.has(id):
				draw_string(f, Vector2(r.end.x - _n(280), y), "%.1f cups" % _cups[id],
					HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19),
					ACCENT if _cups[id] > 0.0 else DIM)
				if i == _sel:
					draw_string(f, Vector2(r.end.x - _n(150), y), "< pour >",
						HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), DIM)

			y += entry_h

	# ---- jar / mix area ----
	var jar: Array = []
	for id in _cups:
		if _cups[id] > 0.0:
			jar.append("%.1f %s" % [_cups[id], Content.ITEMS[id]["name"]])
	draw_line(Vector2(r.position.x + _n(38), r.end.y - _n(126)),
		Vector2(r.end.x - _n(38), r.end.y - _n(126)), EDGE, 2.0)
	draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(94)),
		"JAR:  " + (", ".join(jar) if jar.size() > 0 else "empty"),
		HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(19),
		INK if jar.size() > 0 else DIM)
	draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(64)),
		"up/down select    left/right pour a chemical    [M] mix    [E] read    [I] close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16), DIM)
	if _mix_msg != "":
		draw_multiline_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(36)),
			_mix_msg, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(17), 2, ACCENT)


# ── panel furniture ──────────────────────────────────────────────────────
func _centre(vp: Vector2, w: float, h: float) -> Rect2:
	return Rect2(vp.x * 0.5 - _n(w) * 0.5, vp.y * 0.5 - _n(h) * 0.5, _n(w), _n(h))


func _head(f: Font, r: Rect2, title: String, sub: String) -> void:
	draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(62)), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(27), ACCENT)
	if sub != "":
		var tw: float = f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(27)).x
		draw_string(f, Vector2(r.position.x + _n(52) + tw, r.position.y + _n(62)), sub,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), DIM)
	draw_line(Vector2(r.position.x + _n(38), r.position.y + _n(84)),
		Vector2(r.end.x - _n(38), r.position.y + _n(84)), EDGE, 2.0)


func _foot(f: Font, r: Rect2, text: String) -> void:
	draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(28)), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16), DIM)


func _panel(r: Rect2) -> void:
	draw_rect(r, PANEL)
	draw_rect(r, EDGE, false, 2.0)
