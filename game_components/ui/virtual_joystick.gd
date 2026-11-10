class_name DragJoystick
extends Control

## Virtual drag-to-move joystick for touch and mouse drag input.
## Injects ui_left, ui_right, ui_up, and ui_down actions with analog strength.
## Operates silently without triggering UI tap/click sound.

@export var base_radius: float = 70.0
@export var max_radius: float = 65.0
@export var knob_radius: float = 26.0
@export var deadzone: float = 0.12
@export var dynamic_base: bool = true

var _default_center: Vector2 = Vector2.ZERO
var _base_center: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _input_vector: Vector2 = Vector2.ZERO

var _is_active: bool = false
var _is_animating: bool = false
var _touch_index: int = -1
var _mouse_active: bool = false

var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_default_center()
	resized.connect(_update_default_center)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_drag()

func _exit_tree() -> void:
	_release_drag()

func _update_default_center() -> void:
	# Position resting center comfortably within the bottom-left control box
	_default_center = Vector2(
		clampf(130.0, base_radius + 15.0, size.x - base_radius - 15.0),
		clampf(size.y - 130.0, base_radius + 15.0, size.y - base_radius - 15.0)
	)
	if not _is_active:
		_base_center = _default_center
		_knob_offset = Vector2.ZERO
		queue_redraw()

func _process(_delta: float) -> void:
	if _is_active or _is_animating:
		queue_redraw()

# ── Input Handling ────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_start_drag(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_release_drag()
			accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _touch_index == -1 and not _mouse_active:
				_mouse_active = true
				_start_drag(event.position)
				accept_event()
			elif not event.pressed and _mouse_active:
				_release_drag()
				accept_event()

func _input(event: InputEvent) -> void:
	# Track drag movement anywhere on screen once initiated
	if _touch_index != -1:
		if event is InputEventScreenDrag and event.index == _touch_index:
			_update_drag(event.position)
			_mark_input_handled()
		elif event is InputEventScreenTouch and event.index == _touch_index and not event.pressed:
			_release_drag()
			_mark_input_handled()
	elif _mouse_active:
		if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_update_drag(event.position)
			_mark_input_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_release_drag()
			_mark_input_handled()

func _mark_input_handled() -> void:
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

func _start_drag(local_pos: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_animating = false
	_is_active = true

	if dynamic_base:
		var dist_to_default = local_pos.distance_to(_default_center)
		if dist_to_default <= base_radius * 1.1:
			_base_center = _default_center
			_knob_offset = local_pos - _base_center
		else:
			var margin = base_radius + 15.0
			_base_center = Vector2(
				clampf(local_pos.x, margin, size.x - margin),
				clampf(local_pos.y, margin, size.y - margin)
			)
			_knob_offset = local_pos - _base_center
	else:
		_base_center = _default_center
		_knob_offset = local_pos - _base_center

	_clamp_knob()
	_update_input()
	queue_redraw()

func _update_drag(global_pos: Vector2) -> void:
	var local_pos = global_pos - global_position
	_knob_offset = local_pos - _base_center
	_clamp_knob()
	_update_input()
	queue_redraw()

func _clamp_knob() -> void:
	var dist = _knob_offset.length()
	if dist > max_radius:
		_knob_offset = _knob_offset.normalized() * max_radius

func _release_drag() -> void:
	_touch_index = -1
	_mouse_active = false
	_is_active = false
	_apply_input_vector(Vector2.ZERO)

	if _tween and _tween.is_valid():
		_tween.kill()

	_is_animating = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "_knob_offset", Vector2.ZERO, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_base_center", _default_center, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(func():
		_is_animating = false
		queue_redraw()
	)
	queue_redraw()

# ── Movement Input Injection ──────────────────────────────────────────────────

func _update_input() -> void:
	var raw_vec = _knob_offset / max_radius
	var len = raw_vec.length()
	if len < deadzone:
		_apply_input_vector(Vector2.ZERO)
		return

	var scaled_len = (len - deadzone) / (1.0 - deadzone)
	scaled_len = clampf(scaled_len, 0.0, 1.0)
	var final_vec = raw_vec.normalized() * scaled_len
	_apply_input_vector(final_vec)

func _apply_input_vector(vec: Vector2) -> void:
	_input_vector = vec
	if vec.length_squared() == 0.0:
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_release("ui_down")
		return

	# Horizontal axis
	if vec.x > 0.0:
		Input.action_press("ui_right", vec.x)
		Input.action_release("ui_left")
	elif vec.x < 0.0:
		Input.action_press("ui_left", -vec.x)
		Input.action_release("ui_right")
	else:
		Input.action_release("ui_left")
		Input.action_release("ui_right")

	# Vertical axis
	if vec.y > 0.0:
		Input.action_press("ui_down", vec.y)
		Input.action_release("ui_up")
	elif vec.y < 0.0:
		Input.action_press("ui_up", -vec.y)
		Input.action_release("ui_down")
	else:
		Input.action_release("ui_up")
		Input.action_release("ui_down")

# ── Custom Sci-Fi Cybernetic Drawing ──────────────────────────────────────────

func _draw() -> void:
	var bc = _base_center
	var kp = bc + _knob_offset

	# 1. Base background circle
	var bg_col = Color(0.04, 0.08, 0.16, 0.75 if _is_active else 0.55)
	draw_circle(bc, base_radius, bg_col)

	# 2. Outer ring
	var ring_col = Color(0.3, 0.95, 1.0, 0.85) if _is_active else Color(0.0, 0.75, 1.0, 0.45)
	draw_arc(bc, base_radius, 0.0, TAU, 48, ring_col, 2.0)

	# 3. Inner tactical reference ring
	draw_arc(bc, base_radius * 0.5, 0.0, TAU, 32, Color(0.0, 0.75, 1.0, 0.2), 1.5)

	# 4. Directional indicators (chevrons for Up, Down, Left, Right)
	_draw_directional_indicators(bc)

	# 5. Glowing Quantum Laser Tether between center and knob
	if _knob_offset.length() > 3.0:
		# Outer laser glow
		draw_line(bc, kp, Color(0.0, 0.8, 1.0, 0.35), 4.0)
		# Core laser
		draw_line(bc, kp, Color(0.6, 1.0, 1.0, 0.85), 2.0)
		# Center anchor node
		draw_circle(bc, 4.0, Color(0.3, 1.0, 1.0, 0.7))

	# 6. Knob / Thumbstick
	# Outer glow
	var glow_col = Color(0.0, 0.85, 1.0, 0.45 if _is_active else 0.2)
	draw_circle(kp, knob_radius + 4.0, glow_col)

	# Knob body fill
	var body_col = Color(0.08, 0.22, 0.4, 0.95) if _is_active else Color(0.05, 0.1, 0.2, 0.9)
	draw_circle(kp, knob_radius, body_col)

	# Knob border
	var knob_border_col = Color(0.4, 1.0, 1.0, 1.0) if _is_active else Color(0.0, 0.8, 1.0, 0.75)
	draw_arc(kp, knob_radius, 0.0, TAU, 32, knob_border_col, 2.0)

	# Inner core
	var core_col = Color(0.7, 1.0, 1.0, 1.0) if _is_active else Color(0.3, 0.95, 1.0, 0.75)
	draw_circle(kp, 8.0, core_col)
	draw_circle(kp, 3.0, Color(1.0, 1.0, 1.0, 0.95))

func _draw_directional_indicators(bc: Vector2) -> void:
	var r = base_radius - 12.0
	var active_threshold = 0.35
	var norm = _input_vector

	var dirs = [
		{"dir": Vector2.UP, "active": norm.y < -active_threshold},
		{"dir": Vector2.DOWN, "active": norm.y > active_threshold},
		{"dir": Vector2.LEFT, "active": norm.x < -active_threshold},
		{"dir": Vector2.RIGHT, "active": norm.x > active_threshold}
	]

	for d in dirs:
		var dir_vec: Vector2 = d["dir"]
		var is_dir_active: bool = d["active"]
		var center_pt = bc + dir_vec * r

		var perp = Vector2(-dir_vec.y, dir_vec.x)
		var tip = center_pt + dir_vec * 6.0
		var base1 = center_pt - dir_vec * 4.0 + perp * 5.0
		var base2 = center_pt - dir_vec * 4.0 - perp * 5.0

		var tri = PackedVector2Array([tip, base1, base2])
		if is_dir_active:
			draw_colored_polygon(tri, Color(0.4, 1.0, 1.0, 0.95))
		else:
			draw_polyline(PackedVector2Array([base1, tip, base2]), Color(0.0, 0.75, 1.0, 0.35), 1.5)
