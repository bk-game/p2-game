extends Control

# Interaction prompt, document reader, inventory with mixing, and notebook.
# Everything is drawn in code onto one Control so there is no theme to wire up.
# All sizes derive from S, so the whole interface rescales from one number.

const S := 1.35

const INK    := Color("f0e9db")
const DIM    := Color("b3a992")
const PANEL  := Color(0.10, 0.09, 0.08, 0.94)
const EDGE   := Color("6d5a3e")
const ACCENT := Color("e0b25c")
# What you read is on paper, in ink, held up in front of you.
const PAPER  := Color("efe6d2")
const PAPER_E := Color("cdc0a2")
const PEN    := Color("2c2419")
const PEN_DIM := Color("6f6252")
const RULE   := Color("b19c74")

const FOG    := Color(0.62, 0.82, 0.18)   # the green closing over your eyes
const FOG_DK := Color(0.16, 0.26, 0.06)

enum Mode {PLAY, READ, BAG, NOTES, REPORT, LOCK, CUT, RIDE, CHOICE, OVER, TITLE}

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
var _queued: Array = []
var _read_t := 0.0
var _ride_t := 0.0
var _ride_out := true
var _choice := {}
var _over_t := 0.0

# ── Getting started ──────────────────────────────────────────────────────
# The first minute teaches itself: each step names one thing and waits until
# you have done it, rather than a wall of text before the game starts.
const STEPS := [
	{"say": "Walk", "keys": "W A S D  or the arrow keys",
		"how": "Learn how to walk around."},
	{"say": "Use what you are near", "keys": "E",
		"how": "Anything you can use wears a ring. You have to be facing it."},
	{"say": "Take something", "keys": "E",
		"how": "Some of what you find comes with you."},
	{"say": "See what you are carrying", "keys": "I",
		"how": "The same key puts it away."},
	{"say": "Read what you have worked out", "keys": "N",
		"how": "Anything worth remembering writes itself down."},
]

var _step := -1          # -1 before the title card is dismissed
var _step_t := 0.0
var _walked := 0.0
var _was_at := Vector2.ZERO
var _acted := false
var _title_t := 0.0
var _notes_y := 0.0
var _open_line := 0
var _thought := ""
var _thought_t := 0.0


func _ready() -> void:
	Game.notice.connect(_on_notice)
	Game.toast.connect(_on_toast)
	Game.inventory_changed.connect(func(): queue_redraw())
	Game.notes_changed.connect(func(): queue_redraw())
	Game.open_sink.connect(_open_sink)
	Game.open_lock.connect(_open_lock)
	Game.open_cut.connect(_open_cut)
	Game.ride.connect(_on_ride)
	Game.open_choice.connect(_open_choice)
	Game.level_over.connect(_on_level_over)
	Game.acted.connect(func(): _acted = true)
	Game.thought.connect(_on_thought)
	mode = Mode.TITLE


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


# Two of these can land in the same frame — picking a thing up and what
# picking it up means — so they wait their turn instead of overwriting.
func _on_notice(title: String, body: String) -> void:
	if mode == Mode.READ:
		_queued.append([title, body])
		return
	_title = title
	_body = body
	mode = Mode.READ
	_read_t = 0.0
	queue_redraw()


# Half a thought, in your own voice, under everything else.
func _on_thought(line: String) -> void:
	_thought = line
	_thought_t = 4.5
	queue_redraw()


func _on_toast(text: String) -> void:
	_toast = text
	_toast_t = 5.0
	queue_redraw()


# Opened at the sink, so the chemicals can actually be measured out and
# mixed. Opening it with [I] anywhere else is only a list of what you have.
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


func _open_cut() -> void:
	mode = Mode.CUT
	_code = ""
	_lock_msg = ""
	queue_redraw()


# Pick one of a short list: which key off the press, which lock to turn it
# in. The same panel does both, since both are one press of a number.
# The end of the shift. Nothing to press: it is the last thing on screen.
func _on_level_over() -> void:
	mode = Mode.OVER
	_over_t = 0.0
	_queued.clear()
	queue_redraw()


func _open_choice(data: Dictionary) -> void:
	_choice = data
	mode = Mode.CHOICE
	queue_redraw()


# The drive out to the job and back. The world has already moved under it;
# this is the curtain over the cut.
func _on_ride(outbound: bool) -> void:
	mode = Mode.RIDE
	_ride_t = 0.0
	_ride_out = outbound
	queue_redraw()


func _process(delta: float) -> void:
	if mode == Mode.TITLE:
		_title_t += delta
		queue_redraw()
	if _thought_t > 0.0:
		_thought_t -= delta
		if _thought_t <= 0.0:
			_thought = ""
		queue_redraw()
	if _step >= 0 and _step < STEPS.size():
		_teaching(delta)
	if mode == Mode.OVER:
		_over_t += delta
		queue_redraw()
	if mode == Mode.RIDE:
		_ride_t += delta
		if _ride_t >= RIDE_T:
			mode = Mode.PLAY
			if _ride_out:
				Game.think("arrive")
			else:
				Game.finish_level()
		queue_redraw()
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast = ""
		queue_redraw()
	if mode == Mode.READ or mode == Mode.REPORT:
		if _read_t < 1.0:
			_read_t = minf(_read_t + delta / OPEN_T, 1.0)
			queue_redraw()
	if not is_equal_approx(Game.fog_ratio(), _fog):
		_fog = Game.fog_ratio()
		queue_redraw()


# Watch for the thing the current step asked for, and move on when it lands.
func _teaching(delta: float) -> void:
	_step_t += delta
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	if _was_at != Vector2.ZERO:
		_walked += p.global_position.distance_to(_was_at)
	_was_at = p.global_position
	var got := false
	match _step:
		0: got = _walked > 150.0
		1: got = _acted
		2: got = Game.inventory.size() > 0
		3: got = mode == Mode.BAG
		4: got = mode == Mode.NOTES
	if got and _step_t > 0.4:
		_step += 1
		_step_t = 0.0
		if _step < STEPS.size():
			Sfx.play("pickup", -16.0, 1.5)
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
				if _queued.is_empty():
					mode = Mode.PLAY
				else:
					var nxt: Array = _queued.pop_front()
					_title = nxt[0]
					_body = nxt[1]
					_read_t = 0.0
		Mode.NOTES:
			_notes_key(k)
		Mode.REPORT:
			if k in [KEY_N, KEY_R, KEY_ESCAPE, KEY_E, KEY_I]:
				mode = Mode.PLAY
		Mode.BAG:
			_bag_key(k)
		Mode.LOCK:
			_lock_key(k)
		Mode.CUT:
			_cut_key(k)
		Mode.TITLE:
			# the opening reads itself out a line at a time; any key takes the
			# next one, and the last one puts you on the floor
			_open_line += 1
			_title_t = 0.0
			if _open_line > Content.OPENING.size():
				mode = Mode.PLAY
				_step = 0
				_was_at = Vector2.ZERO
		Mode.RIDE:
			if k in [KEY_E, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
				_ride_t = RIDE_T          # skip to the end of the drive
		Mode.CHOICE:
			_choice_key(k)
		Mode.PLAY:
			if k == KEY_ESCAPE and _step >= 0 and _step < STEPS.size():
				_step = STEPS.size()      # done with being told
			elif k == KEY_I:
				mode = Mode.BAG
				_at_sink = false
				_sel = 0
			elif k == KEY_N:
				mode = Mode.NOTES
				_notes_y = 0.0
			elif k == KEY_R:
				_title = "Field report"
				_body = Game.report()
				mode = Mode.REPORT
			else:
				return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _choice_key(k: int) -> void:
	if k in [KEY_ESCAPE, KEY_Q, KEY_I, KEY_E]:
		mode = Mode.PLAY
		return
	var pick := -1
	if k >= KEY_1 and k <= KEY_9:
		pick = k - KEY_1
	elif k >= KEY_KP_1 and k <= KEY_KP_9:
		pick = k - KEY_KP_1
	var opts: Array = _choice.get("options", [])
	if pick < 0 or pick >= opts.size():
		return
	if _choice.get("kind", "") == "key":
		Game.take_key(pick)
		mode = Mode.PLAY
	elif Game.try_lock(pick):
		mode = Mode.PLAY
		Game.begin_ride(Content.ENTRANCE, true)


# The notebook fills up over a playthrough and used to run off the bottom of
# its own page. Up and down move through it.
func _notes_key(k: int) -> void:
	if k in [KEY_N, KEY_ESCAPE, KEY_E, KEY_I]:
		mode = Mode.PLAY
		return
	match k:
		KEY_UP: _notes_y -= _n(46)
		KEY_DOWN: _notes_y += _n(46)
		KEY_PAGEUP: _notes_y -= _n(300)
		KEY_PAGEDOWN: _notes_y += _n(300)
		KEY_HOME: _notes_y = 0.0
		KEY_END: _notes_y = 1e9      # clamped against the content when drawn


# Which of the four marks to take, and in what order. Same entry as the
# dial, but three slots and each mark only once.
func _cut_key(k: int) -> void:
	if k in [KEY_ESCAPE, KEY_Q, KEY_I]:
		mode = Mode.PLAY
		return
	if k == KEY_BACKSPACE:
		_code = _code.substr(0, maxi(_code.length() - 1, 0))
		_lock_msg = ""
		return
	if k in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		if _code.length() < Content.CUT_MARKS.size():
			_lock_msg = "All four, in order."
			return
		# Right or wrong, the panel closes: a bound blade has to be worked out
		# of the limb before there is anything to take an order in.
		mode = Mode.PLAY
		Game.try_cut(_code)
		_code = ""
		return
	var mark := -1
	if k >= KEY_1 and k <= KEY_4:
		mark = k - KEY_0
	elif k >= KEY_KP_1 and k <= KEY_KP_4:
		mark = k - KEY_KP_0
	if mark > 0 and _code.length() < Content.CUT_MARKS.size() \
			and not _code.contains(str(mark)):
		_code += str(mark)
		_lock_msg = ""


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


# At the sink the list is shown in two parts, what goes in the mix and what
# does not; everywhere else it is just what you are carrying. Selection runs
# down the panel as drawn, so it has to follow the same order.
func _bag_order() -> Array:
	if not _at_sink:
		return Array(Game.inventory)
	# At the basin the rest of what you are carrying is not the question.
	var mixable := []
	for id in Game.inventory:
		if _cups.has(id):
			mixable.append(id)
	return mixable


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
			if _at_sink and _sel < bag.size() and _cups.has(bag[_sel]):
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
				_mix_msg = "Not here. This wants a basin and a tap running."
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

	# ── carrying summary; the full list lives in the inventory panel ────
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
	var hint := "[E] interact   [I] inventory   [N] notebook   [R] report"
	var hw: float = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22)).x
	var hr := Rect2(vp.x - hw - _n(60), vp.y - _n(70), hw + _n(40), _n(46))
	_panel(hr)
	draw_string(f, Vector2(hr.position.x + _n(20), hr.position.y + _n(31)), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22), INK)

	# ── what you are saying to yourself ─────────────────────────────────
	if _thought != "" and mode == Mode.PLAY:
		_draw_thought(f, vp)

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

	# ── the tutorial, while there is any of it left ─────────────────────
	var taught: bool = _step >= 0 and _step < STEPS.size()
	if taught and mode == Mode.PLAY:
		_draw_teaching(f, vp)

	# ── toast ───────────────────────────────────────────────────────────
	if _toast != "":
		var tr := Rect2(vp.x * 0.5 - _n(430), _n(26) + (_n(104) if taught else 0.0),
			_n(860), _n(74))
		_panel(tr)
		draw_multiline_string(f, Vector2(tr.position.x + _n(20), tr.position.y + _n(30)),
			_toast, HORIZONTAL_ALIGNMENT_LEFT, tr.size.x - _n(40), _fs(17), 2, INK)

	match mode:
		Mode.READ, Mode.REPORT: _draw_reader(f, vp)
		Mode.NOTES: _draw_notes(f, vp)
		Mode.BAG: _draw_inventory(f, vp)
		Mode.LOCK: _draw_lock(f, vp)
		Mode.CUT: _draw_cut(f, vp)
		Mode.RIDE: _draw_ride(f, vp)
		Mode.CHOICE: _draw_choice(f, vp)
		Mode.OVER: _draw_over(f, vp)
		Mode.TITLE: _draw_title(f, vp)


func _draw_lock(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 560, 340)
	_panel(r)
	_head(f, r, "LOCKED", "four digits")
	draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(126)),
		"A dial set into the bedroom door. Four digits, and somebody chose a "
		+ "date they could not lose.", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76),
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


func _draw_cut(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 640, 380)
	_panel(r)
	_head(f, r, "THE GRAIN", "four hearts in it")
	draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(124)),
		"Take them in the order the grain will give. Take them wrong and the "
		+ "blade sticks fast.",
		HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(17), DIM)
	for i in Content.CUT_MARKS.size():
		draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(160) + i * _n(28)),
			"%d   %s" % [i + 1, Content.CUT_MARKS[i]],
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19), INK)
	var slot: float = _n(50)
	var x0: float = r.get_center().x + _n(24)
	for i in Content.CUT_MARKS.size():
		var box := Rect2(x0 + i * (slot + _n(10)), r.position.y + _n(168), slot, _n(66))
		draw_rect(box, Color(0, 0, 0, 0.45))
		draw_rect(box, EDGE, false, 2.0)
		if i < _code.length():
			draw_string(f, Vector2(box.position.x + _n(18), box.end.y - _n(20)),
				_code[i], HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(30), ACCENT)
	if _lock_msg != "":
		draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(64)), _lock_msg,
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(17), INK)
	_foot(f, r, "1-4 in order    backspace    [E] cut    [I] step back")


# The card the game opens on. Nothing to read but the name and what you are:
# one key gets you onto the floor.
func _draw_title(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.02, 0.03))
	var mid := vp.x * 0.5
	var t: float = clampf(_title_t / 0.8, 0.0, 1.0)

	# the last card is the name of the game. The crawl has already said who
	# you work for, and the rule under it is drawn to whatever the name is.
	if _open_line >= Content.OPENING.size():
		var name := title_text()
		var nw: float = f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(42)).x
		draw_string(f, Vector2(mid - nw * 0.5, vp.y * 0.44), name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(42), Color(ACCENT, t))
		var half: float = nw * 0.5 + _n(34)
		draw_line(Vector2(mid - half, vp.y * 0.44 + _n(22)),
			Vector2(mid + half, vp.y * 0.44 + _n(22)), Color(EDGE, t), 2.0)
	else:
		var line: String = Content.OPENING[_open_line]
		var w := _n(760)
		draw_multiline_string(f, Vector2(mid - w * 0.5, vp.y * 0.44), line,
			HORIZONTAL_ALIGNMENT_CENTER, w, _fs(26), -1, Color(INK, t))

	if _title_t > 0.8:
		var go := "press any key"
		var gw: float = f.get_string_size(go, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16)).x
		var pulse: float = 0.3 + 0.22 * sin(_title_t * 2.4)
		draw_string(f, Vector2(mid - gw * 0.5, vp.y - _n(90)), go,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16), Color(DIM, pulse))
	# how far through the opening you are
	for i in Content.OPENING.size() + 1:
		var dot := Vector2(mid - Content.OPENING.size() * _n(9) + i * _n(18),
			vp.y - _n(54))
		draw_circle(dot, 3.0, ACCENT if i <= _open_line else Color(EDGE, 0.7))


# What the game is called, taken from the project itself so the card and the
# window title cannot drift apart.
func title_text() -> String:
	return str(ProjectSettings.get_setting("application/config/name",
		"Personal Effects")).to_upper()


# What you say to yourself, sitting under the game rather than over it.
func _draw_thought(f: Font, vp: Vector2) -> void:
	var fade: float = clampf(_thought_t, 0.0, 1.0) * clampf((4.5 - _thought_t) / 0.4,
		0.0, 1.0)
	var said := "\"%s\"" % _thought
	var w: float = f.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19)).x
	var at := Vector2(vp.x * 0.5 - w * 0.5, vp.y - _n(196))
	draw_rect(Rect2(at.x - _n(18), at.y - _n(26), w + _n(36), _n(38)),
		Color(0, 0, 0, 0.45 * fade))
	draw_string(f, at, said, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19),
		Color(0.86, 0.83, 0.72, fade))


# One step at a time along the top of the screen, each waiting on the thing
# it asked for. It stops being drawn the moment the last one lands.
func _draw_teaching(f: Font, vp: Vector2) -> void:
	var step: Dictionary = STEPS[_step]
	var w := _n(620)
	var r := Rect2(vp.x * 0.5 - w * 0.5, _n(26), w, _n(98))
	_panel(r)
	draw_string(f, Vector2(r.position.x + _n(24), r.position.y + _n(36)),
		step["say"], HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22), INK)
	var keys: String = step["keys"]
	var kw: float = f.get_string_size(keys, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18)).x
	var cap := Rect2(r.end.x - _n(24) - kw - _n(20), r.position.y + _n(16),
		kw + _n(20), _n(30))
	draw_rect(cap, Color(1, 1, 1, 0.07))
	draw_rect(cap, EDGE, false, 2.0)
	draw_string(f, Vector2(cap.position.x + _n(10), cap.end.y - _n(9)), keys,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), ACCENT)
	draw_multiline_string(f, Vector2(r.position.x + _n(24), r.position.y + _n(60)),
		step["how"], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(48), _fs(16), 1, DIM)
	# how far along, and the way out of being taught
	for i in STEPS.size():
		var dot := Vector2(r.position.x + _n(24) + i * _n(16), r.end.y - _n(12))
		draw_circle(dot, 3.5, ACCENT if i <= _step else Color(EDGE, 0.8))
	var skip := "[Esc] skip"
	var sw2: float = f.get_string_size(skip, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(14)).x
	draw_string(f, Vector2(r.end.x - _n(24) - sw2, r.end.y - _n(9)), skip,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(14), DIM)


# The shift is over: what came back, what it paid, and what the handler made
# of it, on black, with nothing else on screen.
func _draw_over(f: Font, vp: Vector2) -> void:
	var t: float = clampf(_over_t / 0.9, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.02, 0.03, t))
	if t < 0.55:
		return
	var a: float = (t - 0.55) / 0.45
	var found := Game.story_found()
	var total := Game.story_total()
	var mid := vp.x * 0.5
	var y: float = vp.y * 0.24

	var title := "END OF SHIFT"
	var tw: float = f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(40)).x
	draw_string(f, Vector2(mid - tw * 0.5, y), title, HORIZONTAL_ALIGNMENT_LEFT,
		-1, _fs(40), Color(ACCENT, a))
	y += _n(24)
	draw_line(Vector2(mid - _n(220), y), Vector2(mid + _n(220), y),
		Color(EDGE, a), 2.0)
	y += _n(58)

	var rows := [
		["SUBJECT", "Wood, Joseph"],
		["BODY", "recovered" if Game.flag("found_body") else "not recovered"],
		["RECOVERED", "%d of %d significant items" % [found, total]],
		["PAID", "$%d" % (found * 250)],
	]
	for row in rows:
		draw_string(f, Vector2(mid - _n(220), y), row[0], HORIZONTAL_ALIGNMENT_LEFT,
			-1, _fs(20), Color(DIM, a))
		draw_string(f, Vector2(mid - _n(20), y), row[1], HORIZONTAL_ALIGNMENT_LEFT,
			-1, _fs(20), Color(INK, a))
		y += _n(38)

	y += _n(26)
	var said := "Handler: \"This is barely a person. Half of him is missing and we "
	said += "cannot invent the rest.\""
	if found >= total:
		said = "Handler: \"Complete. We can build him properly. Whatever you did "
		said += "in there, do it again next time.\""
	elif found >= total * 0.6:
		said = "Handler: \"Enough to work with. Gaps in the middle of his life, "
		said += "though. He will come out a little thin.\""
	draw_multiline_string(f, Vector2(mid - _n(220), y), said,
		HORIZONTAL_ALIGNMENT_LEFT, _n(440), _fs(18), -1, Color(DIM, a))

	var end := "There is another one in the morning."
	var ew: float = f.get_string_size(end, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17)).x
	draw_string(f, Vector2(mid - ew * 0.5, vp.y - _n(90)), end,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), Color(DIM, a * 0.8))


func _draw_choice(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var opts: Array = _choice.get("options", [])
	var r := _centre(vp, 640, 268.0 + opts.size() * 42.0)
	_panel(r)
	_head(f, r, _choice.get("title", ""), "")
	draw_multiline_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(122)),
		_choice.get("blurb", ""), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76),
		_fs(17), -1, DIM)
	for i in opts.size():
		var y: float = r.position.y + _n(188) + i * _n(42)
		var cap := Rect2(r.position.x + _n(38), y - _n(22), _n(30), _n(30))
		draw_rect(cap, Color(1, 1, 1, 0.07))
		draw_rect(cap, EDGE, false, 2.0)
		draw_string(f, Vector2(cap.position.x + _n(10), cap.end.y - _n(9)),
			str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), ACCENT)
		# the tag itself, in its colour, when this is the press
		var tint := INK
		if _choice.get("kind", "") == "key":
			tint = Color(Content.ITEMS[Content.KEYS[i]["id"]]["tint"])
			draw_rect(Rect2(cap.end.x + _n(14), y - _n(16), _n(18), _n(18)), tint)
		var at: float = cap.end.x + (_n(42) if _choice.get("kind", "") == "key"
			else _n(14))
		draw_string(f, Vector2(at, y), opts[i], HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(19), INK)
	var how := "1-%d to take one" if _choice.get("kind", "") == "key" \
		else "1-%d to turn it there"
	_foot(f, r, (how % opts.size()) + "    [E] step back")


# ── The drive ────────────────────────────────────────────────────────────
const RIDE_T    := 4.2     # how long the journey takes
const RIDE_FADE := 0.6     # black at each end of it, over the cut
const RIDE_SPD  := 720.0   # how fast the road goes by


# Seen from above, like everything else: a road going up the screen, the car
# holding the middle of it, and the woods coming past on both sides.
func _draw_ride(f: Font, vp: Vector2) -> void:
	var t := _ride_t
	var scroll := t * RIDE_SPD
	draw_rect(Rect2(Vector2.ZERO, vp), Color("0d1410"))

	# the road and its verges
	var rw: float = vp.x * 0.24
	var road := Rect2(vp.x * 0.5 - rw * 0.5, 0.0, rw, vp.y)
	draw_rect(Rect2(road.position.x - _n(14), 0.0, rw + _n(28), vp.y), Color("2a2b24"))
	draw_rect(road, Color("32323a"))
	var dash := _n(52)
	var gap := _n(44)
	var y: float = fposmod(scroll, dash + gap) - dash
	while y < vp.y:
		draw_rect(Rect2(vp.x * 0.5 - _n(3), y, _n(6), dash), Color("cbbf86"))
		y += dash + gap

	# the woods, on both sides, deterministic so nothing pops about
	for i in 46:
		var n1 := Mat.noise(i * 3.7, 1.3)
		var n2 := Mat.noise(i * 5.1, 7.7)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = vp.x * 0.5 + side * (rw * 0.62 + n1 * vp.x * 0.46)
		var span: float = vp.y * 1.4
		var ty: float = fposmod(n2 * span + scroll * (0.92 + n1 * 0.2), span) - vp.y * 0.2
		var rr: float = _n(24) + n1 * _n(30)
		draw_circle(Vector2(x, ty), rr, Color("14240f"))
		draw_circle(Vector2(x - rr * 0.22, ty - rr * 0.22), rr * 0.72, Color("1e3417"))
		draw_circle(Vector2(x, ty), rr * 0.2, Color("2c2118"))

	# the car, holding the middle, headlights thrown up the road
	var cx: float = vp.x * 0.5 + sin(t * 1.7) * _n(6)
	var cy: float = vp.y * 0.62
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - _n(20), cy - _n(40)), Vector2(cx - _n(120), cy - _n(430)),
		Vector2(cx + _n(120), cy - _n(430)), Vector2(cx + _n(20), cy - _n(40))]),
		Color(1, 0.95, 0.78, 0.07))
	var body := Rect2(cx - _n(34), cy - _n(62), _n(68), _n(124))
	draw_colored_polygon(Mat.rr(Rect2(body.position + Vector2(_n(5), _n(7)),
		body.size), _n(16)), Color(0, 0, 0, 0.45))
	draw_colored_polygon(Mat.rr(body, _n(16)), Color("2e3a4a"))
	draw_colored_polygon(Mat.rr(Rect2(cx - _n(27), cy - _n(34), _n(54), _n(40)),
		_n(8)), Color("18202b"))                      # windscreen and roof
	draw_colored_polygon(Mat.rr(Rect2(cx - _n(24), cy + _n(14), _n(48), _n(26)),
		_n(6)), Color("222c39"))
	for s2 in [-1.0, 1.0]:
		draw_circle(Vector2(cx + s2 * _n(22), cy - _n(54)), _n(6),
			Color(1, 0.96, 0.82, 0.95))               # headlights
		draw_circle(Vector2(cx + s2 * _n(22), cy + _n(54)), _n(5),
			Color(0.75, 0.16, 0.12, 0.9))             # tail lights

	# a line about the drive, and the way out of it
	var says := "Forty minutes out." if _ride_out else "Forty minutes back."
	if t > RIDE_T * 0.55:
		says = "The trees close in." if _ride_out else "The lights of the yard."
	var w: float = f.get_string_size(says, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22)).x
	draw_string(f, Vector2(vp.x * 0.5 - w * 0.5, vp.y - _n(96)), says,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(22), INK)
	draw_string(f, Vector2(vp.x - _n(150), vp.y - _n(40)), "[E] skip",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16), DIM)

	# black over the cut at each end
	var into: float = 1.0 - clampf(t / RIDE_FADE, 0.0, 1.0)
	var outof: float = clampf((t - (RIDE_T - RIDE_FADE)) / RIDE_FADE, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, maxf(into, outof)))


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


const READ_W   := 900.0    # the reader is always this wide
const READ_MAX := 760.0    # and never taller than this
const READ_PAD := 190.0    # heading and footer
const LABEL_W  := 250.0    # the label column of a form
const OPEN_T   := 0.13     # how long the sheet takes to come up


# How much the document currently loaded overruns the reader at the smallest
# type it will drop to. Zero or less means the whole of it is on the page.
func reader_overflow() -> float:
	var probe := _centre(size, READ_W, READ_MAX)
	return _reader_flow(ThemeDB.fallback_font, probe, _fs(13), false) \
		- _n(READ_MAX - READ_PAD)


# A sheet of paper held up in front of you, rather than a panel of the
# interface: it comes up as you lift it, the type is ink on paper, and the
# key that puts it away is drawn as the key.
func _draw_reader(f: Font, vp: Vector2) -> void:
	var t: float = clampf(_read_t, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.6 * t))

	var probe := _centre(vp, READ_W, READ_MAX)
	var fs := _fs(19)
	var h := _reader_flow(f, probe, fs, false)
	while h > _n(READ_MAX - READ_PAD) and fs > _fs(13):
		fs = maxi(fs - 2, _fs(13))
		h = _reader_flow(f, probe, fs, false)
	var r := _centre(vp, READ_W, clampf(h / S + READ_PAD, 340.0, READ_MAX))

	# lift it into place: scale about the middle of the sheet
	var k: float = 0.955 + 0.045 * t
	var c := r.get_center()
	draw_set_transform(c * (1.0 - k), 0.0, Vector2(k, k))

	# the sheet, its shadow, and the shading down its right edge
	draw_colored_polygon(Mat.rr(Rect2(r.position + Vector2(_n(7), _n(10)), r.size),
		_n(4)), Color(0, 0, 0, 0.4))
	draw_colored_polygon(Mat.rr(r, _n(4)), PAPER)
	draw_colored_polygon(Mat.rr(Rect2(r.end.x - _n(26), r.position.y, _n(26),
		r.size.y), _n(4)), Color(PAPER_E, 0.5))
	var edge := Mat.rr(r, _n(4))
	edge.append(edge[0])
	draw_polyline(edge, Color(PAPER_E, 0.9), 2.0)

	# heading, ruled off
	draw_string(f, Vector2(r.position.x + _n(38), r.position.y + _n(62)), _title,
		HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(26), PEN)
	draw_line(Vector2(r.position.x + _n(38), r.position.y + _n(82)),
		Vector2(r.end.x - _n(38), r.position.y + _n(82)), RULE, 2.0)

	_reader_flow(f, r, fs, true)

	# the key that puts it away, drawn as a key
	var cap := Rect2(r.position.x + _n(38), r.end.y - _n(56), _n(30), _n(30))
	draw_colored_polygon(Mat.rr(cap, _n(5)), Color(PEN, 0.10))
	var cape := Mat.rr(cap, _n(5))
	cape.append(cape[0])
	draw_polyline(cape, Color(PEN, 0.45), 2.0)
	draw_string(f, Vector2(cap.position.x + _n(9), cap.end.y - _n(9)), "E",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), PEN)
	draw_string(f, Vector2(cap.end.x + _n(12), cap.end.y - _n(9)), "put it away",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), PEN_DIM)
	if not _queued.is_empty():
		var more := "%d more to look at" % _queued.size()
		var mw: float = f.get_string_size(more, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(17)).x
		draw_string(f, Vector2(r.end.x - _n(38) - mw, cap.end.y - _n(9)), more,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), PEN_DIM)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Lay the document out, and draw it if asked. A line with a tab in it is a
# form field — label in one column, value in the next — so a certificate
# reads like a certificate instead of a paragraph. Returns the height used.
func _reader_flow(f: Font, r: Rect2, fs: int, draw_it: bool) -> float:
	var x: float = r.position.x + _n(38)
	var w: float = r.size.x - _n(76)
	var top: float = r.position.y + _n(112)
	var y := top
	for line in _body.split("\n"):
		if line.strip_edges().is_empty():
			y += fs * 0.5
			continue
		var tab := line.find("\t")
		if tab == -1:
			var ph: float = f.get_multiline_string_size(line,
				HORIZONTAL_ALIGNMENT_LEFT, w, fs).y
			if draw_it:
				draw_multiline_string(f, Vector2(x, y), line,
					HORIZONTAL_ALIGNMENT_LEFT, w, fs, -1, PEN)
			y += ph + _n(5)
			continue
		var label := line.substr(0, tab).strip_edges()
		var value := line.substr(tab + 1).strip_edges()
		var vw: float = w - _n(LABEL_W)
		var vh: float = f.get_multiline_string_size(value,
			HORIZONTAL_ALIGNMENT_LEFT, vw, fs).y
		if draw_it:
			draw_string(f, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT,
				_n(LABEL_W) - _n(14), fs, PEN_DIM)
			draw_multiline_string(f, Vector2(x + _n(LABEL_W), y), value,
				HORIZONTAL_ALIGNMENT_LEFT, vw, fs, -1, PEN)
		y += vh + _n(5)
	return y - top


# How tall the writing is, and how much of it fits — the two numbers the
# scrolling is clamped against, exposed so a test can hold them to it.
func notes_span() -> float:
	var r := _centre(size, 900, 600)
	return (r.end.y - _n(52)) - (r.position.y + _n(126))


func notes_height() -> float:
	var f := ThemeDB.fallback_font
	var r := _centre(size, 900, 600)
	var wide: float = r.size.x - _n(120)
	var total := 0.0
	for n in Game.notes:
		total += f.get_multiline_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, wide,
			_fs(18)).y + _n(16)
	return maxf(total - _n(16), 0.0)


func _draw_notes(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 900, 600)
	_panel(r)

	# the band the writing lives in, between the heading and the footer
	var top: float = r.position.y + _n(126)
	var bot: float = r.end.y - _n(52)
	var wide: float = r.size.x - _n(120)
	var gap := _n(16)

	var total := 0.0
	for n in Game.notes:
		total += f.get_multiline_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, wide,
			_fs(18)).y + gap
	total = maxf(total - gap, 0.0)
	_notes_y = clampf(_notes_y, 0.0, maxf(total - (bot - top), 0.0))

	if Game.notes.is_empty():
		draw_string(f, Vector2(r.position.x + _n(38), top + _n(20)),
			"Nothing written down yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(19), DIM)
	var y: float = top - _notes_y
	for n in Game.notes:
		var h: float = f.get_multiline_string_size(n, HORIZONTAL_ALIGNMENT_LEFT,
			wide, _fs(18)).y
		if y + h > top - _n(30) and y < bot + _n(30):
			draw_string(f, Vector2(r.position.x + _n(38), y), "-",
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18), ACCENT)
			draw_multiline_string(f, Vector2(r.position.x + _n(62), y), n,
				HORIZONTAL_ALIGNMENT_LEFT, wide, _fs(18), -1, INK)
		y += h + gap

	# mask whatever ran past the band, then put the furniture back over it.
	# The panel itself is not quite opaque, so one coat leaves the line you
	# scrolled past ghosting through the heading.
	var over := Rect2(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 4.0,
		top - r.position.y - _n(14))
	var under := Rect2(r.position.x + 2.0, bot + _n(6), r.size.x - 4.0,
		r.end.y - bot - _n(6) - 2.0)
	for coat in 3:
		draw_rect(over, PANEL)
		draw_rect(under, PANEL)
	draw_rect(r, EDGE, false, 2.0)
	_head(f, r, "NOTEBOOK", "%d of %d significant items recovered"
		% [Game.story_found(), Game.story_total()])

	# how far down it you are
	if total > bot - top:
		var track := Rect2(r.end.x - _n(30), top, _n(4), bot - top)
		draw_rect(track, Color(EDGE, 0.5))
		var frac: float = (bot - top) / total
		var thumb: float = maxf(track.size.y * frac, _n(24))
		var at: float = track.position.y + (track.size.y - thumb) \
			* (_notes_y / maxf(total - (bot - top), 1.0))
		draw_rect(Rect2(track.position.x, at, track.size.x, thumb), ACCENT)
		_foot(f, r, "up/down to read through it    [N] close")
	else:
		_foot(f, r, "[N] close")


func _draw_inventory(f: Font, vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var r := _centre(vp, 980, 700)
	_panel(r)
	_head(f, r, "AT THE SINK" if _at_sink else "INVENTORY",
		"" if _at_sink else "carrying %d" % Game.inventory.size())

	var bag := _bag_order()
	var y: float = r.position.y + _n(118)
	if _at_sink:
		y = _bag_section(f, r, y, "WHAT GOES IN THE MIX", bag, 0, false)
	else:
		y = _bag_section(f, r, y, "", bag, 0, true)

	# ── what the selected thing is for, and the basin under it ──────────
	draw_line(Vector2(r.position.x + _n(38), r.end.y - _n(150)),
		Vector2(r.end.x - _n(38), r.end.y - _n(150)), EDGE, 2.0)
	var how := _how_to_use(bag[_sel] if _sel < bag.size() else "")
	if how != "":
		draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(120)),
			"USE:  " + how, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(18), INK)
	if _at_sink:
		var basin := []
		for id in _cups:
			if _cups[id] > 0.0:
				basin.append("%.1f %s" % [_cups[id], Content.ITEMS[id]["name"]])
		draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(90)),
			"IN THE BASIN:  " + (", ".join(basin) if basin.size() > 0 else "empty"),
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(19),
			INK if basin.size() > 0 else DIM)
	draw_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(60)),
		_bag_controls(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16), DIM)
	if _mix_msg != "":
		draw_multiline_string(f, Vector2(r.position.x + _n(38), r.end.y - _n(32)),
			_mix_msg, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - _n(76), _fs(17), 2, ACCENT)


# One part of the list. The mix goes in a single column with its cup
# controls; everything else is two columns, so a full bag still fits.
func _bag_section(f: Font, r: Rect2, y: float, label: String, ids: Array,
		first: int, two_col: bool) -> float:
	if label != "":
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
	if _at_sink and _cups.has(id):
		draw_string(f, Vector2(x + w - _n(240), y), "%.1f cups" % _cups[id],
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(18),
			ACCENT if _cups[id] > 0.0 else DIM)
		if idx == _sel:
			draw_string(f, Vector2(x + w - _n(120), y), "< pour >",
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17), DIM)


# The controls line says where mixing is possible, since [M] does nothing
# unless it was opened at the sink.
func _bag_controls() -> String:
	if _at_sink:
		return "up/down select    left/right measure out    [M] mix    [E] read    [I] close"
	return "up/down select    [E] read    [I] close"


# What a thing is actually for. Carrying a fire extinguisher tells you
# nothing about walking it up to the haze and pressing E.
func _how_to_use(id: String) -> String:
	if id == "":
		return ""
	var it: Dictionary = Content.ITEMS[id]
	if it.get("use", "") != "":
		return it["use"]
	if _cups.has(id):
		if _at_sink:
			return "Left/right to measure out cups, then [M] to mix."
		return "A chemical. Nothing to measure it into here."
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
