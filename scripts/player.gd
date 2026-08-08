extends CharacterBody2D

@export var speed := 260.0

const C_SHADOW := Color(0, 0, 0, 0.18)
const C_SHIRT  := Color("3f5d8a")
const C_SHIRT2 := Color("344d73")
const C_SKIN   := Color("e8b98f")
const C_HAIR   := Color("4a3626")
const C_EDGE   := Color("2b2b30")

const REACH := 34.0
const ARC   := PI * 0.4   # half-angle of the cone you have to be turned into
const TOUCH := 16.0       # closer than this, whatever you are stood on counts

var facing := -PI / 2.0
var _target: Node2D = null

@onready var _hud: Control = get_tree().get_first_node_in_group("hud")


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if _hud != null and _hud.blocking():
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("left", "right", "up", "down")
	velocity = dir * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		var want := dir.angle()
		facing = lerp_angle(facing, want, 0.35)
		queue_redraw()
	_scan()
	_saw(delta)


# Cutting a limb is a hold, not a tap: a couple of seconds of sawing with the
# cracks opening up as you go. Let go, or turn away, and it closes back up.
func _saw(delta: float) -> void:
	var progress := 0.0
	var holding := Input.is_key_pressed(KEY_E)
	for n in get_tree().get_nodes_in_group("act"):
		if not is_instance_valid(n) or not n.has_method("cuttable"):
			continue
		if n == _target and holding and n.cuttable():
			progress = n.saw(delta)
		else:
			n.relax(delta)
	if _hud != null:
		_hud.set_progress(progress)


# Nearest interactable within reach, and in front of you, drives the
# on-screen prompt.
func _scan() -> void:
	# Nearest wins, but small things you came for get a head start over
	# scenery, so an item lying against a limb is picked up rather than
	# masked by it — without a distant item masking what you are touching.
	var best: Node2D = null
	var best_score := INF
	for n in get_tree().get_nodes_in_group("act"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var at: Vector2 = n.reach_point(global_position) if n.has_method("reach_point") \
			else (n as Node2D).global_position
		var d := global_position.distance_to(at)
		# Most things are at arm's length, but a thing can ask for more room:
		# a cupboard is furniture you open, not a spot you have to line up on.
		if d >= (n.reach() if n.has_method("reach") else REACH):
			continue
		# You have to be turned towards a thing to work on it. Anything you
		# are all but standing on is exempt: which way you last walked says
		# nothing about an item under your feet.
		if d > TOUCH and absf(angle_difference(facing, (at - global_position).angle())) > ARC:
			continue
		var score: float = d - (n.bias() if n.has_method("bias") else 0.0)
		if score < best_score:
			best = n
			best_score = score
	_target = best
	if _hud != null:
		_hud.set_prompt(best.prompt() if best != null else "")


func _unhandled_key_input(e: InputEvent) -> void:
	if _hud != null and _hud.blocking():
		return
	if e is InputEventKey and e.pressed and not e.echo \
			and (e as InputEventKey).keycode == KEY_E:
		if is_instance_valid(_target):
			_target.act()
			_scan()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_set_transform(Vector2(0, 3), 0.0, Vector2.ONE)
	_ellipse(Vector2.ZERO, 20, 17, C_SHADOW)

	# Body is drawn facing +x, then rotated to the travel direction.
	draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
	_ellipse(Vector2(-1, 0), 17, 16, C_SHIRT)
	_ellipse(Vector2(-7, 0), 10, 15, C_SHIRT2)
	_ellipse(Vector2(5, -14), 5, 5, C_SKIN)   # hands
	_ellipse(Vector2(5, 14), 5, 5, C_SKIN)
	_ellipse(Vector2(3, 0), 11, 11, C_SKIN)   # head
	_arc_cap(Vector2(3, 0), 11, PI * 0.45, PI * 1.55, C_HAIR)
	draw_arc(Vector2(3, 0), 11, 0, TAU, 28, C_EDGE, 1.5)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _arc_cap(c: Vector2, r: float, a0: float, a1: float, col: Color) -> void:
	var pts := PackedVector2Array([c])
	for i in 17:
		var a: float = lerp(a0, a1, i / 16.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)
