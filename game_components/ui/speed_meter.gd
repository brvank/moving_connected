class_name SpeedMeter
extends Control

## Cybernetic Speed Control Drag Meter.
## Sits on the right side of the gameplay screen.
## Allows the user to drag up/down to adjust movement speed from precision crawl (25%) to full thrust (100%).

signal speed_changed(multiplier: float)

@export var min_speed: float = 0.25
@export var max_speed: float = 1.0
@export var current_value: float = 1.0 # 0.0 (min_speed) to 1.0 (max_speed)

var _is_dragging: bool = false
var _touch_index: int = -1
var _mouse_active: bool = false

var _track_top: float = 30.0
var _track_bottom: float = 270.0
var _track_height: float = 240.0

@onready var label_value: Label = $LabelValue
@onready var label_title: Label = $LabelTitle

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Initialize from GameManager if set
	if get_node_or_null("/root/GameManager") != null:
		var mult: float = GameManager.player_speed_multiplier
		current_value = clampf((mult - min_speed) / (max_speed - min_speed), 0.0, 1.0)
	resized.connect(update_layout)
	update_layout()
	_update_labels()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_drag()

func update_layout() -> void:
	var font_sz: int = clampi(int(size.y * 0.05), 11, 22)
	var title_sz: int = clampi(int(size.y * 0.04), 9, 16)
	var header_h: float = font_sz + 10.0
	var footer_h: float = title_sz + 10.0

	if label_value:
		label_value.position = Vector2(0, 4.0)
		label_value.size = Vector2(size.x, header_h)
		label_value.add_theme_font_size_override("font_size", font_sz)

	if label_title:
		label_title.position = Vector2(0, size.y - footer_h - 2.0)
		label_title.size = Vector2(size.x, footer_h)
		label_title.add_theme_font_size_override("font_size", title_sz)

	_track_top = header_h + 6.0
	_track_bottom = size.y - footer_h - 6.0
	_track_height = maxf(10.0, _track_bottom - _track_top)
	queue_redraw()

func _update_labels() -> void:
	if label_value:
		var pct: int = int(round(get_speed_multiplier() * 100.0))
		label_value.text = "%d%%" % pct

func get_speed_multiplier() -> float:
	return lerpf(min_speed, max_speed, current_value)

func set_meter_value(val: float) -> void:
	current_value = clampf(val, 0.0, 1.0)
	var mult: float = get_speed_multiplier()
	if get_node_or_null("/root/GameManager") != null:
		GameManager.player_speed_multiplier = mult
	_update_labels()
	queue_redraw()
	speed_changed.emit(mult)

func _update_from_pos(pos: Vector2) -> void:
	if _track_height <= 0.0:
		return
	var y: float = clampf(pos.y, _track_top, _track_bottom)
	# Top is 1.0 (max speed), bottom is 0.0 (min speed)
	var raw_t: float = 1.0 - (y - _track_top) / _track_height
	set_meter_value(raw_t)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_is_dragging = true
			_update_from_pos(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_release_drag()
			accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _touch_index == -1 and not _mouse_active:
				_mouse_active = true
				_is_dragging = true
				_update_from_pos(event.position)
				accept_event()
			elif not event.pressed and _mouse_active:
				_release_drag()
				accept_event()

func _input(event: InputEvent) -> void:
	if _touch_index != -1:
		if event is InputEventScreenDrag and event.index == _touch_index:
			_update_from_pos(event.position - global_position)
			_mark_handled()
		elif event is InputEventScreenTouch and event.index == _touch_index and not event.pressed:
			_release_drag()
			_mark_handled()
	elif _mouse_active:
		if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_update_from_pos(event.position - global_position)
			_mark_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_release_drag()
			_mark_handled()

func _mark_handled() -> void:
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

func _release_drag() -> void:
	_touch_index = -1
	_mouse_active = false
	_is_dragging = false
	queue_redraw()

func _draw() -> void:
	# 1. Outer Chassis Panel
	var bg_col: Color = Color(0.04, 0.08, 0.16, 0.75 if _is_dragging else 0.6)
	var border_col: Color = Color(0.3, 0.95, 1.0, 0.9) if _is_dragging else Color(0.0, 0.75, 1.0, 0.5)
	draw_rect(Rect2(Vector2.ZERO, size), bg_col, true)
	draw_rect(Rect2(Vector2.ZERO, size), border_col, false, 2.0)

	# 2. Track Channel
	var track_w: float = clampf(size.x * 0.32, 12.0, 26.0)
	var track_x: float = (size.x - track_w) * 0.5
	var track_rect: Rect2 = Rect2(track_x, _track_top, track_w, _track_height)
	draw_rect(track_rect, Color(0.02, 0.035, 0.07, 0.95), true)
	draw_rect(track_rect, Color(0.0, 0.7, 1.0, 0.35), false, 1.0)

	# 3. Energy Fill Bar
	var handle_y: float = _track_bottom - current_value * _track_height
	var fill_h: float = _track_bottom - handle_y
	if fill_h > 1.0:
		var fill_rect: Rect2 = Rect2(track_x + 1.0, handle_y, track_w - 2.0, fill_h)
		var energy_col: Color = Color(0.0, 0.75, 1.0, 0.5) if not _is_dragging else Color(0.2, 0.9, 1.0, 0.65)
		draw_rect(fill_rect, energy_col, true)
		# Glowing core laser beam down center
		draw_line(
			Vector2(size.x * 0.5, _track_bottom),
			Vector2(size.x * 0.5, handle_y),
			Color(0.6, 1.0, 1.0, 0.85),
			2.0
		)

	# 4. Graduation Tick Marks (0%, 25%, 50%, 75%, 100%)
	for step in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var ty: float = _track_bottom - step * _track_height
		var is_major: bool = (step == 0.0 or step == 0.5 or step == 1.0)
		var tick_len: float = 6.0 if is_major else 4.0
		var tick_col: Color = Color(0.4, 1.0, 1.0, 0.7) if is_major else Color(0.0, 0.75, 1.0, 0.35)
		# Left tick
		draw_line(Vector2(track_x - tick_len - 2.0, ty), Vector2(track_x - 2.0, ty), tick_col, 1.0)
		# Right tick
		draw_line(Vector2(track_x + track_w + 2.0, ty), Vector2(track_x + track_w + tick_len + 2.0, ty), tick_col, 1.0)

	# 5. Drag Handle / Throttle Knob
	var handle_w: float = size.x * 0.78
	var handle_h: float = clampf(_track_height * 0.08, 16.0, 30.0)
	var handle_rect: Rect2 = Rect2((size.x - handle_w) * 0.5, handle_y - handle_h * 0.5, handle_w, handle_h)

	# Handle glow when dragging
	if _is_dragging:
		draw_rect(handle_rect.grow(3.0), Color(0.0, 0.85, 1.0, 0.3), true)

	# Handle body fill & border
	var handle_body_col: Color = Color(0.08, 0.24, 0.44, 0.95) if _is_dragging else Color(0.05, 0.12, 0.22, 0.92)
	var handle_border_col: Color = Color(0.4, 1.0, 1.0, 1.0) if _is_dragging else Color(0.0, 0.85, 1.0, 0.8)
	draw_rect(handle_rect, handle_body_col, true)
	draw_rect(handle_rect, handle_border_col, false, 2.0)

	# Handle center pip / grip grooves
	var grip_y: float = handle_rect.position.y + handle_h * 0.5
	var grip_w: float = handle_w * 0.45
	var gx1: float = (size.x - grip_w) * 0.5
	var gx2: float = gx1 + grip_w
	draw_line(Vector2(gx1, grip_y), Vector2(gx2, grip_y), Color(0.6, 1.0, 1.0, 0.95), 2.0)
	if handle_h >= 20.0:
		draw_line(Vector2(gx1 + 3.0, grip_y - 3.5), Vector2(gx2 - 3.0, grip_y - 3.5), Color(0.0, 0.75, 1.0, 0.5), 1.0)
		draw_line(Vector2(gx1 + 3.0, grip_y + 3.5), Vector2(gx2 - 3.0, grip_y + 3.5), Color(0.0, 0.75, 1.0, 0.5), 1.0)
