extends CanvasLayer

## On-screen 4-button directional touch controls (Top, Down, Left, Right)
## and Cybernetic Speed Control Drag Meter.
## Dynamically scales to half the screen height for comfortable use on high-resolution devices.
## Supports multi-touch, tapping, and thumb-sliding across directional buttons.

@onready var dpad: Control = $DPad
@onready var btn_up: Button = %BtnUp
@onready var btn_down: Button = %BtnDown
@onready var btn_left: Button = %BtnLeft
@onready var btn_right: Button = %BtnRight
@onready var speed_meter: SpeedMeter = $SpeedMeter

var _button_size: float = 90.0
var _active_touches: Dictionary = {} # int (index) -> Vector2 (local pos)
var _mouse_active: bool = false
var _mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Prevent SoundManager from playing UI click audio on movement button taps
	for btn in [btn_up, btn_down, btn_left, btn_right]:
		btn.set_meta("no_sound", true)

	dpad.gui_input.connect(_on_dpad_gui_input)
	dpad.draw.connect(_on_dpad_draw)

	update_layout()
	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(update_layout):
		vp.size_changed.connect(update_layout)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()
	elif what == NOTIFICATION_WM_SIZE_CHANGED:
		update_layout()

func _exit_tree() -> void:
	_release_all()

func update_layout() -> void:
	var vp = get_viewport()
	var screen_h: float = 0.0
	if vp:
		screen_h = vp.get_visible_rect().size.y
	if screen_h <= 0.0:
		screen_h = 648.0

	var target_size: float = screen_h * 0.48
	var margin: float = maxf(12.0, target_size * 0.05)

	# 1. Update DPad layout on bottom-left
	dpad.custom_minimum_size = Vector2(target_size, target_size)
	dpad.size = Vector2(target_size, target_size)
	dpad.anchor_left = 0.0
	dpad.anchor_top = 1.0
	dpad.anchor_right = 0.0
	dpad.anchor_bottom = 1.0
	dpad.offset_left = margin
	dpad.offset_bottom = -margin
	dpad.offset_right = margin + target_size
	dpad.offset_top = -margin - target_size
	dpad.grow_horizontal = Control.GROW_DIRECTION_END
	dpad.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var gap: float = target_size * 0.03
	var b_size: float = (target_size - 4.0 * gap) / 3.0
	_button_size = b_size

	var c: Vector2 = Vector2(target_size * 0.5, target_size * 0.5)

	# Up (Top)
	btn_up.position = Vector2(c.x - b_size * 0.5, gap)
	btn_up.size = Vector2(b_size, b_size)

	# Down (Bottom)
	btn_down.position = Vector2(c.x - b_size * 0.5, target_size - gap - b_size)
	btn_down.size = Vector2(b_size, b_size)

	# Left
	btn_left.position = Vector2(gap, c.y - b_size * 0.5)
	btn_left.size = Vector2(b_size, b_size)

	# Right
	btn_right.position = Vector2(target_size - gap - b_size, c.y - b_size * 0.5)
	btn_right.size = Vector2(b_size, b_size)

	dpad.queue_redraw()

	# 2. Update SpeedMeter layout on bottom-right
	if speed_meter:
		var meter_w: float = clampf(target_size * 0.25, 60.0, 110.0)
		speed_meter.custom_minimum_size = Vector2(meter_w, target_size)
		speed_meter.size = Vector2(meter_w, target_size)
		speed_meter.anchor_left = 1.0
		speed_meter.anchor_top = 1.0
		speed_meter.anchor_right = 1.0
		speed_meter.anchor_bottom = 1.0
		speed_meter.offset_left = -margin - meter_w
		speed_meter.offset_bottom = -margin
		speed_meter.offset_right = -margin
		speed_meter.offset_top = -margin - target_size
		speed_meter.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		speed_meter.grow_vertical = Control.GROW_DIRECTION_BEGIN
		speed_meter.update_layout()

func _on_dpad_draw() -> void:
	var c: Vector2 = dpad.size * 0.5
	var hub_radius: float = _button_size * 0.45
	# Center tactical cybernetic hub
	dpad.draw_circle(c, hub_radius, Color(0.04, 0.08, 0.16, 0.55))
	dpad.draw_arc(c, hub_radius, 0.0, TAU, 32, Color(0.0, 0.75, 1.0, 0.35), 1.5)
	dpad.draw_circle(c, 3.5, Color(0.3, 0.95, 1.0, 0.75))

# ── Touch & Mouse Input Handling ──────────────────────────────────────────────

func _on_dpad_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = event.position
		else:
			_active_touches.erase(event.index)
		_update_directions()
		dpad.accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_active = true
				_mouse_pos = event.position
			else:
				_mouse_active = false
			_update_directions()
			dpad.accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if _active_touches.has(event.index):
			_active_touches[event.index] = event.position - dpad.global_position
			_update_directions()
			_mark_handled()
	elif event is InputEventScreenTouch:
		if not event.pressed and _active_touches.has(event.index):
			_active_touches.erase(event.index)
			_update_directions()
			_mark_handled()
	elif event is InputEventMouseMotion:
		if _mouse_active:
			_mouse_pos = event.position - dpad.global_position
			_update_directions()
			_mark_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _mouse_active:
			_mouse_active = false
			_update_directions()
			_mark_handled()

func _mark_handled() -> void:
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

func _update_directions() -> void:
	var want_up := false
	var want_down := false
	var want_left := false
	var want_right := false

	var center := dpad.size * 0.5
	var deadzone := _button_size * 0.22
	var max_dist := dpad.size.x * 0.65

	var positions: Array[Vector2] = []
	for idx in _active_touches:
		positions.append(_active_touches[idx])
	if _mouse_active:
		positions.append(_mouse_pos)

	var rect_up := btn_up.get_rect()
	var rect_down := btn_down.get_rect()
	var rect_left := btn_left.get_rect()
	var rect_right := btn_right.get_rect()

	for pos in positions:
		var diff := pos - center
		var dist := diff.length()
		if dist < deadzone or dist > max_dist:
			continue

		# Check explicit button bounding rects
		if rect_up.has_point(pos):
			want_up = true
		if rect_down.has_point(pos):
			want_down = true
		if rect_left.has_point(pos):
			want_left = true
		if rect_right.has_point(pos):
			want_right = true

		# Directional thresholds for thumb sliding & diagonals
		var norm := diff.normalized()
		if norm.y < -0.38:
			want_up = true
		elif norm.y > 0.38:
			want_down = true

		if norm.x < -0.38:
			want_left = true
		elif norm.x > 0.38:
			want_right = true

	_set_action_state("ui_up", btn_up, want_up)
	_set_action_state("ui_down", btn_down, want_down)
	_set_action_state("ui_left", btn_left, want_left)
	_set_action_state("ui_right", btn_right, want_right)

func _set_action_state(action: StringName, btn: Button, is_active: bool) -> void:
	if is_active:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
		btn.button_pressed = true
	else:
		if Input.is_action_pressed(action):
			Input.action_release(action)
		btn.button_pressed = false

func _release_all() -> void:
	_active_touches.clear()
	_mouse_active = false
	if btn_up:
		_set_action_state("ui_up", btn_up, false)
	if btn_down:
		_set_action_state("ui_down", btn_down, false)
	if btn_left:
		_set_action_state("ui_left", btn_left, false)
	if btn_right:
		_set_action_state("ui_right", btn_right, false)
