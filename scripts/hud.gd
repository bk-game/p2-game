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
const FOG    := Color(0.62, 0.82, 0.18)   # the green closing over your eyes
const FOG_DK := Color(0.16, 0.26, 0.06)

enum Mode {PLAY, READ, BAG, NOTES, REPORT, LOCK}

var mode: int = Mode.PLAY
var _title := ""
var _body := ""
var _toast := ""
var _toast_t := 0.0
var _prompt := ""
var _cups := {"norust": 0.0, "bleach": 0.0, "exfluid": 0.0, "water": 0.0}
var _sel := 0
var _mix_msg := ""
var _at_sink := false
var _progress := 0.0
var _fog := 0.0
var _code := ""
var _lock_msg := ""


func _ready() -> void:
	Game.notice.connect(_on_notice)
	Game.toast.connect(_on_toast)
	Game.inventory_changed.connect(func(): queue_redraw())
	Game.notes_changed.connect(func(): queue_redraw())
	Game.open_sink.connect(_open_sink)
	Game.open_lock.connect(_open_lock)


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


# Opened at the sink, so the chemicals can actually be mixed. Opening the bag
# with [I] anywhere else only lets you look through it.
func _open_sink() -> void:
	mode = Mode.BAG
	_at_sink = true
	_mix_msg = ""
	queue_redraw()


func _open_lock() -> void:
	mode = Mode.LOCK
	_code = ""
	_lock_msg = ""
	queue_redraw()


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast = ""
		queue_redraw()
	if not is_equal_approx(Game.fog_ratio(), _fog):
		_fog = Game.fog_ratio()
		queue_redraw()


# ── sizing helpers ───────────────────────────────────────────────────────
func _n(v: float) -> float:
	return v * S


func _fs(v: int) -> int:
	return int(round(v * S))


# ══ Input ════════════════════════════════════════════════════════════════
func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var k := (e as InputEventKey).keycode
	match mode:
		Mode.READ:
			if k in [KEY_E, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
				mode = Mode.PLAY
		Mode.NOTES, Mode.REPORT:
			if k in [KEY_N, KEY_R, KEY_ESCAPE, KEY_E, KEY_I]:
				mode = Mode.PLAY
		Mode.BAG:
			_bag_key(k)
		Mode.LOCK:
			_lock_key(k)
		Mode.PLAY:
			if k == KEY_I:
				mode = Mode.BAG
				_at_sink = false
				_sel = 0
			elif k == KEY_C:
				var lamp := get_tree().get_first_node_in_group("light")
				if lamp != null:
					lamp.toggle()
			elif k == KEY_N:
				mode = Mode.NOTES
			elif k == KEY_R:
				_title = "Field report"
				_body = Game.report()
				mode = Mode.REPORT
			else:
				return
	get_viewport().set_input_as_handled()
	queue_redraw()


# Four digits on a dial. Numbers go in, backspace takes one back off, and
# enter tries it.
func _lock_key(k: int) -> void:
	if k in [KEY_ESCAPE, KEY_Q, KEY_I]:
		mode = Mode.PLAY
		return
	if k == KEY_BACKSPACE:
		_code = _code.substr(0, maxi(_code.length() - 1, 0))
		_lock_msg = ""
		return
	if k in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		if _code.length() < 4:
			_lock_msg = "Four digits."
			return
		if Game.try_code(_code):
			mode = Mode.PLAY
		else:
			_lock_msg = "Nothing moves. Not that one."
			_code = ""
		return
	var digit := -1
	if k >= KEY_0 and k <= KEY_9:
		digit = k - KEY_0
	elif k >= KEY_KP_0 and k <= KEY_KP_9:
		digit = k - KEY_KP_0
	if digit >= 0 and _code.length() < 4:
		_code += str(digit)
		_lock_msg = ""


# The bag is shown in two parts: what goes in the mix, then everything else.
# Selection runs down the panel as drawn, so it has to follow the same order.
func _bag_order() -> Array:
	var mixable := []
	var rest := []
	for id in Game.inventory:
		if _cups.has(id):
			mixable.append(id)
		else:
			rest.append(id)
	return mixable + rest


func _bag_key(k: int) -> void:
	var bag := _bag_order()
	match k:
		KEY_ESCAPE, KEY_Q, KEY_I:
			mode = Mode.PLAY
		KEY_UP:
			_sel = maxi(_sel - 1, 0)
		KEY_DOWN:
			_sel = mini(_sel + 1, maxi(bag.size() - 1, 0))
		KEY_RIGHT, KEY_LEFT:
			if _sel < bag.size() and _cups.has(bag[_sel]):
				var step := 0.5 if k == KEY_RIGHT else -0.5
				_cups[bag[_sel]] = clampf(_cups[bag[_sel]] + step, 0.0, 5.0)
		KEY_ENTER, KEY_E:
			if _sel < bag.size():
				var it: Dictionary = Content.ITEMS[bag[_sel]]
				_title = it["name"]
				_body = it["body"]
				mode = Mode.READ
		KEY_M:
			if not _at_sink:
				_mix_msg = "Not here. Joe mixed this in the bathroom sink — you " \
					+ "need a basin and a tap."
				return
			_mix_msg = Game.mix(_cups)
			if Game.flag("made_solution"):
				for c in _cups:
					_cups[c] = 0.0


# ══ Drawing ══════════════════════════════════════════════════════════════
func _draw() -> void:
	var f := ThemeDB.fallback_font
	var vp := size

	if _fog > 0.0:
		_draw_fog(vp)

	# ── carrying summary; the full list lives in the bag panel ──────────
	var st := ["%d carried  [I]" % Game.inventory.size()]
	if Game.solution_charges > 0:
		st.append("solution x%d" % Game.solution_charges)
	if Game.has_item("extinguisher"):
		st.append("extinguisher x%d" % Game.extinguisher_charges)
	var line := "   ".join(st)
	var bw: float = f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18)).x + _n(40)
	var bar := Rect2(_n(20), vp.y - _n(70), bw, _n(46))
	_panel(bar)
	draw_string(f, Vector2(bar.position.x + _n(20), bar.position.y + _n(31)), line,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), INK)

	# ── key hints ───────────────────────────────────────────────────────
	var hint := "[E] interact   [I] bag   [N] notebook   [C] lantern   [R] report"
	var hw: float = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22)).x
	var hr := Rect2(vp.x - hw - _n(60), vp.y - _n(70), hw + _n(40), _n(46))
	_panel(hr)
	draw_string(f, Vector2(hr.position.x + _n(20), hr.position.y + _n(31)), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22), INK)

	# ── interaction prompt ──────────────────────────────────────────────
	if _prompt != "" and mode == Mode.PLAY:
		var w: float = f.get_string_size(_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(19)).x + _n(64)
		var pr := Rect2(vp.x * 0.5 - w * 0.5, vp.y - _n(140), w, _n(44))
		_panel(pr)
		draw_string(f, Vector2(pr.position.x + _n(20), pr.position.y + _n(30)),
			"E  " + _prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19), INK)
		if _progress > 0.0:
			var track := Rect2(pr.position.x + _n(14), pr.end.y + _n(8),
				pr.size.x - _n(28), _n(10))
			draw_rect(track, Color(0, 0, 0, 0.55))
			draw_rect(Rect2(track.position, Vector2(track.size.x * _progress,
				track.size.y)), ACCENT)
			draw_rect(track, EDGE, false, 2.0)

	# ── toast ───────────────────────────────────────────────────────────
	if _toast != "":
		var tr := Rect2(vp.x * 0.5 - _n(430), _n(26), _n(860), _n(74))
		_panel(tr)
		draw_multiline_string(f, Vector2(tr.position.x + _n(20), tr.position.y + _n(30)),
			_toast, HORIZONTAL_ALIGNMENT_LEFT, tr.size.x - _n(40), _fs(17), 2, INK)

	match mode:
		Mode.READ, Mode.REPORT: _draw_reader(f, vp)
		Mode.NOTES: _draw_notes(f, vp)
		Mode.BAG: _draw_bag(f, vp)
		Mode.LOCK: _draw_lock(f, vp)


func _draw_lock(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 560, 340)
	_panel(r)
	_head(f, r, "LOCKED", "four digits")
	draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(126)),
		"A dial in the bathroom door. Somebody chose these four numbers because "
		+ "they could not lose them.", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76),
		_fs(17), DIM)
	# the four slots, filled left to right as you type
	var slot: float = _n(56)
	var x0: float = r.get_center().x - slot * 2.0 - _n(18)
	for i in 4:
		var box := Rect2(x0 + i * (slot + _n(12)), r.position.y + _n(176), slot, _n(66))
		draw_rect(box, Color(0, 0, 0, 0.45))
		draw_rect(box, EDGE, false, 2.0)
		if i < _code.length():
			draw_string(f, Vector2(box.position.x + _n(18), box.end.y - _n(20)),
				_code[i], HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(30), ACCENT)
	if _lock_msg != "":
		draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(64)), _lock_msg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), INK)
	_foot(f, r, "0-9 dial    backspace    [E] try it    [I] step away")


# What breathing the green looks like from inside it: the whole view goes
# green and the edges close in, deeper the longer you stand there.
func _draw_fog(vp: Vector2) -> void:
	var t: float = clampf(_fog, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(FOG, 0.45 * t))
	var step: float = vp.y * 0.055
	for i in 9:                       # edges closing in, darkest outermost
		var f: float = 1.0 - float(i) / 9.0
		var inset: float = i * step
		draw_rect(Rect2(inset + step * 0.5, inset + step * 0.5,
			vp.x - inset * 2.0 - step, vp.y - inset * 2.0 - step),
			Color(FOG_DK, 0.16 * t * f * f), false, step)
	# your own pulse, once it is really taking hold
	if t > 0.5:
		var beat: float = (t - 0.5) * 2.0
		draw_rect(Rect2(Vector2.ZERO, vp), Color(FOG_DK, 0.22 * beat * beat))


func _draw_reader(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 860, 540)
	_panel(r)
	_head(f, r, _title, "")
	draw_multiline_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(120)),
		_body, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(19), -1, INK)
	_foot(f, r, "[E] put it away")


func _draw_notes(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 900, 600)
	_panel(r)
	_head(f, r, "NOTEBOOK", "%d of %d significant items recovered"
		% [Game.story_found(), Game.story_total()])
	var y: float = r.position.y + _n(146)
	if Game.notes.is_empty():
		draw_string(f, Vector2(r.position.x + _n(38), y), "Nothing written down yet.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19), DIM)
	for n in Game.notes:
		var h: float = f.get_multiline_string_size(n, HORIZONTAL_ALIGNMENT_LEFT,
			r.size.x - _n(104), _fs(18)).y
		draw_string(f, Vector2(r.position.x + _n(38), y), "-",
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), ACCENT)
		draw_multiline_string(f, Vector2(r.position.x + _n(62), y), n,
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(104), _fs(18), -1, INK)
		y += h + _n(16)
	_foot(f, r, "[N] close")


func _draw_bag(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 980, 700)
	_panel(r)
	_head(f, r, "BAG", "carrying %d%s" % [Game.inventory.size(),
		"    at the bathroom sink" if _at_sink else ""])

	var bag := _bag_order()
	var mixable := 0
	for id in bag:
		if _cups.has(id):
			mixable += 1

	var y: float = r.position.y + _n(118)
	y = _bag_section(f, r, y, "GOES IN THE MIX", bag.slice(0, mixable), 0, false)
	y = _bag_section(f, r, y, "EVERYTHING ELSE", bag.slice(mixable), mixable, true)

	# ── what the selected thing is for, and the jar under it ────────────
	draw_line(Vector2(r.position.x + _n(38), r.end.y - _n(150)),
		Vector2(r.end.x - _n(38), r.end.y - _n(150)), EDGE, 2.0)
	var how := _how_to_use(bag[_sel] if _sel < bag.size() else "")
	if how != "":
		draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(120)),
			"USE:  " + how, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(18), INK)
	var jar := []
	for id in _cups:
		if _cups[id] > 0.0:
			jar.append("%.1f %s" % [_cups[id], Content.ITEMS[id]["name"]])
	draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(90)),
		"IN THE BASIN:  " + (", ".join(jar) if jar.size() > 0 else "empty"),
		HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(19),
		INK if jar.size() > 0 else DIM)
	draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(60)),
		_bag_controls(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16), DIM)
	if _mix_msg != "":
		draw_multiline_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(32)),
			_mix_msg, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(17), 2, ACCENT)


# One labelled part of the bag. The mix goes in a single column with its cup
# controls; everything else is two columns, so a full bag still fits.
func _bag_section(f: Font, r: Rect2, y: float, label: String, ids: Array,
		first: int, two_col: bool) -> float:
	draw_string(f, Vector2(r.position.x + _n(38), y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(15), ACCENT)
	y += _n(28)
	if ids.is_empty():
		draw_string(f, Vector2(r.position.x + _n(58), y), "nothing yet",
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), DIM)
		return y + _n(34)
	var full: float = r.size.x - _n(76)
	if not two_col:
		for i in ids.size():
			_bag_row(f, ids[i], first + i, r.position.x + _n(38), y + i * _n(32), full)
		return y + ids.size() * _n(32) + _n(20)
	var rows := int(ceil(ids.size() / 2.0))
	for i in ids.size():
		var col: int = i / rows
		_bag_row(f, ids[i], first + i, r.position.x + _n(38) + col * full * 0.5,
			y + (i % rows) * _n(28), full * 0.5)
	return y + rows * _n(28) + _n(20)


func _bag_row(f: Font, id: String, idx: int, x: float, y: float, w: float) -> void:
	var it: Dictionary = Content.ITEMS[id]
	if idx == _sel:
		draw_rect(Rect2(x - _n(10), y - _n(20), w, _n(28)), Color(1, 1, 1, 0.07))
		draw_string(f, Vector2(x, y), ">", HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(19), ACCENT)
	draw_rect(Rect2(x + _n(22), y - _n(13), _n(12), _n(17)), Color(it["tint"]))
	draw_string(f, Vector2(x + _n(44), y), it["name"], HORIZONTAL_ALIGNMENT_LEFT,
		w - _n(170), _fs(18), INK)
	if _cups.has(id):
		draw_string(f, Vector2(x + w - _n(240), y), "%.1f cups" % _cups[id],
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18),
			ACCENT if _cups[id] > 0.0 else DIM)
		if idx == _sel:
			draw_string(f, Vector2(x + w - _n(120), y), "< pour >",
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), DIM)


# The controls line says where mixing is possible, since [M] does nothing
# unless the bag was opened at the sink.
func _bag_controls() -> String:
	return "up/down select    left/right pour a chemical    %s    [E] read    [I] close" \
		% ("[M] mix" if _at_sink else "[M] mix — only at the bathroom sink")


# What a thing is actually for. Carrying a fire extinguisher tells you
# nothing about walking it up to the haze and pressing E.
func _how_to_use(id: String) -> String:
	if id == "":
		return ""
	var it: Dictionary = Content.ITEMS[id]
	if it.get("use", "") != "":
		return it["use"]
	if _cups.has(id):
		return "Left/right to measure out cups, then [M] to mix."
	return "[E] to read it again."


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
