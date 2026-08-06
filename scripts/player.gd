extends CharacterBody2D

@export var speed := 260.0

const C_SHADOW := Color(0, 0, 0, 0.18)
const C_SHIRT  := Color("3f5d8a")
const C_SHIRT2 := Color("344d73")
const C_SKIN   := Color("e8b98f")
const C_HAIR   := Color("4a3626")
const C_EDGE   := Color("2b2b30")

const REACH := 78.0    #needs to be tweaked 

var facing := -PI / 2.0
var _target: Node2D = null

@onready var _hud: Control = get_tree().get_first_node_in_group("hud")


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if _hud != null and _hud.blocking():
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		var want := dir.angle()
		facing = lerp_angle(facing, want, 0.35)
		queue_redraw()
	_scan()
	_saw(delta)


# Cutting a limb is a hold, not a tap: five seconds of sawing with the cracks
# opening up as you go. Let go, or walk off, and it closes back up.
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


# Nearest interactable within reach drives the on-screen prompt.
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
		if d >= REACH:
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
