extends CanvasLayer

## Touch and on-screen controls overlay.
## Handles directional movement (D-Pad) and the 3 awarded controls:
## 1. Separators (Horizontal, Vertical, Close/Far toggle)
## 2. Circular rotation (Clockwise, Anti-Clockwise)
## 3. Size changer (Scale Up, Scale Down, Reset)

# D-Pad buttons
@onready var btn_left: Button = %BtnLeft
@onready var btn_right: Button = %BtnRight
@onready var btn_up: Button = %BtnUp
@onready var btn_down: Button = %BtnDown

# Awarded controls container & tabs
@onready var award_panel: PanelContainer = %AwardedControls
@onready var tab_sep: Button = %TabSep
@onready var tab_rot: Button = %TabRot
@onready var tab_size: Button = %TabSize

# Content panels
@onready var sep_panel: Control = %SepPanel
@onready var rot_panel: Control = %RotPanel
@onready var size_panel: Control = %SizePanel

# Separator buttons
@onready var btn_sep_switch: Button = %BtnSepSwitch
@onready var btn_sep_h: Button = %BtnSepH
@onready var btn_sep_v: Button = %BtnSepV

# Circular buttons
@onready var btn_rot_cw: Button = %BtnRotCW
@onready var btn_rot_ccw: Button = %BtnRotCCW

# Size changer buttons
@onready var scale_label: Label = %ScaleLabel
@onready var btn_scale_down: Button = %BtnScaleDown
@onready var btn_scale_reset: Button = %BtnScaleReset
@onready var btn_scale_up: Button = %BtnScaleUp

# State
var _sep_mode_close: bool = true
var _holding_sep_h: bool = false
var _holding_sep_v: bool = false
var _holding_rot_cw: bool = false
var _holding_rot_ccw: bool = false
var _current_scale: float = 1.0
var _active_tab: int = 0

const CONTROL_SPEED: float = 240.0
const ROTATION_SPEED: float = 220.0

# Styles for tabs
var _style_active: StyleBoxFlat
var _style_inactive: StyleBoxFlat

func _ready() -> void:
	# Setup tab styles
	_style_active = StyleBoxFlat.new()
	_style_active.bg_color = Color(0.25, 0.45, 0.8, 0.9)
	_style_active.corner_radius_top_left = 6
	_style_active.corner_radius_top_right = 6
	_style_active.corner_radius_bottom_right = 6
	_style_active.corner_radius_bottom_left = 6

	_style_inactive = StyleBoxFlat.new()
	_style_inactive.bg_color = Color(0.15, 0.18, 0.25, 0.6)
	_style_inactive.corner_radius_top_left = 6
	_style_inactive.corner_radius_top_right = 6
	_style_inactive.corner_radius_bottom_right = 6
	_style_inactive.corner_radius_bottom_left = 6

	# Connect D-Pad buttons
	_connect_action_button(btn_left, "ui_left")
	_connect_action_button(btn_right, "ui_right")
	_connect_action_button(btn_up, "ui_up")
	_connect_action_button(btn_down, "ui_down")

	# Connect tab switching
	tab_sep.pressed.connect(func(): _select_tab(0))
	tab_rot.pressed.connect(func(): _select_tab(1))
	tab_size.pressed.connect(func(): _select_tab(2))

	# Connect Separators
	btn_sep_switch.pressed.connect(_on_sep_switch_toggled)
	_connect_hold_button(btn_sep_h, func(held: bool): _holding_sep_h = held)
	_connect_hold_button(btn_sep_v, func(held: bool): _holding_sep_v = held)

	# Connect Circular
	_connect_hold_button(btn_rot_cw, func(held: bool): _holding_rot_cw = held)
	_connect_hold_button(btn_rot_ccw, func(held: bool): _holding_rot_ccw = held)

	# Connect Size Changer
	btn_scale_up.pressed.connect(_on_scale_up_pressed)
	btn_scale_down.pressed.connect(_on_scale_down_pressed)
	btn_scale_reset.pressed.connect(_on_scale_reset_pressed)

	_update_unlocked_controls()

func _update_unlocked_controls() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var has_sep = (gm == null or gm.has_separators_unlocked())
	var has_rot = (gm == null or gm.has_circular_unlocked())
	var has_size = (gm == null or gm.has_size_changer_unlocked())

	tab_sep.visible = has_sep
	tab_rot.visible = has_rot
	tab_size.visible = has_size

	if not has_sep and not has_rot and not has_size:
		# No awarded controls unlocked yet (e.g. World 1 early levels)
		award_panel.visible = false
	else:
		award_panel.visible = true
		if has_sep:
			_select_tab(0)
		elif has_rot:
			_select_tab(1)
		elif has_size:
			_select_tab(2)

func _select_tab(tab_idx: int) -> void:
	_active_tab = tab_idx
	# Reset hold states on tab switch
	_holding_sep_h = false
	_holding_sep_v = false
	_holding_rot_cw = false
	_holding_rot_ccw = false

	sep_panel.visible = (tab_idx == 0)
	rot_panel.visible = (tab_idx == 1)
	size_panel.visible = (tab_idx == 2)

	tab_sep.add_theme_stylebox_override("normal", _style_active if tab_idx == 0 else _style_inactive)
	tab_rot.add_theme_stylebox_override("normal", _style_active if tab_idx == 1 else _style_inactive)
	tab_size.add_theme_stylebox_override("normal", _style_active if tab_idx == 2 else _style_inactive)

func _connect_action_button(btn: Button, action: StringName) -> void:
	btn.button_down.connect(func(): Input.action_press(action))
	btn.button_up.connect(func(): Input.action_release(action))

func _connect_hold_button(btn: Button, callback: Callable) -> void:
	btn.button_down.connect(func(): callback.call(true))
	btn.button_up.connect(func(): callback.call(false))

# ── Separator Handlers ────────────────────────────────────────────────────────

func _on_sep_switch_toggled() -> void:
	_sep_mode_close = not _sep_mode_close
	if _sep_mode_close:
		btn_sep_switch.text = "Mode: Close ⇥⇤"
	else:
		btn_sep_switch.text = "Mode: Far ⇤⇥"

# ── Size Changer Handlers ──────────────────────────────────────────────────────

func _on_scale_up_pressed() -> void:
	_current_scale = clampf(_current_scale + 0.25, 0.5, 2.0)
	_apply_scale_to_players()

func _on_scale_down_pressed() -> void:
	_current_scale = clampf(_current_scale - 0.25, 0.5, 2.0)
	_apply_scale_to_players()

func _on_scale_reset_pressed() -> void:
	_current_scale = 1.0
	_apply_scale_to_players()

func _apply_scale_to_players() -> void:
	scale_label.text = "Player Size: %.2fx" % _current_scale
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if is_instance_valid(p) and p.has_method("set_target_scale"):
			p.set_target_scale(_current_scale)

# ── Keyboard Shortcuts ────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not award_panel.visible:
		return

	if event is InputEventKey:
		# Tab switching via 1, 2, 3
		if event.pressed and not event.echo:
			if event.keycode == KEY_1 and tab_sep.visible:
				_select_tab(0)
			elif event.keycode == KEY_2 and tab_rot.visible:
				_select_tab(1)
			elif event.keycode == KEY_3 and tab_size.visible:
				_select_tab(2)
			elif event.keycode == KEY_M and _active_tab == 0:
				_on_sep_switch_toggled()
			elif event.keycode == KEY_R and _active_tab == 2:
				_on_scale_reset_pressed()
			elif event.keycode == KEY_EQUAL or event.keycode == KEY_E and _active_tab == 2:
				_on_scale_up_pressed()
			elif event.keycode == KEY_MINUS or event.keycode == KEY_Q and _active_tab == 2:
				_on_scale_down_pressed()

		# Hold keys for Separators
		if _active_tab == 0:
			if event.keycode == KEY_H:
				_holding_sep_h = event.pressed
			elif event.keycode == KEY_V:
				_holding_sep_v = event.pressed

		# Hold keys for Circular
		if _active_tab == 1:
			if event.keycode == KEY_C:
				_holding_rot_cw = event.pressed
			elif event.keycode == KEY_X:
				_holding_rot_ccw = event.pressed

# ── Physics Process & Awarded Movements ───────────────────────────────────────

func _physics_process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.size() < 2:
		return

	var p1: Node2D = players[0]
	var p2: Node2D = players[1]
	if not is_instance_valid(p1) or not is_instance_valid(p2):
		return

	var center = (p1.global_position + p2.global_position) / 2.0
	var p1_vel = Vector2.ZERO
	var p2_vel = Vector2.ZERO

	# 1. Separators
	if _holding_sep_h:
		var dx = p2.global_position.x - p1.global_position.x
		if _sep_mode_close:
			# Move close horizontally towards center X (stop if within 32px)
			if abs(dx) > 32.0:
				var dir1 = signf(center.x - p1.global_position.x)
				var dir2 = signf(center.x - p2.global_position.x)
				p1_vel.x += dir1 * CONTROL_SPEED
				p2_vel.x += dir2 * CONTROL_SPEED
		else:
			# Move far horizontally away from center X
			var dir1 = signf(p1.global_position.x - center.x)
			var dir2 = signf(p2.global_position.x - center.x)
			if dir1 == 0:
				dir1 = -1.0
				dir2 = 1.0
			p1_vel.x += dir1 * CONTROL_SPEED
			p2_vel.x += dir2 * CONTROL_SPEED

	if _holding_sep_v:
		var dy = p2.global_position.y - p1.global_position.y
		if _sep_mode_close:
			# Move close vertically towards center Y (stop if within 32px)
			if abs(dy) > 32.0:
				var dir1 = signf(center.y - p1.global_position.y)
				var dir2 = signf(center.y - p2.global_position.y)
				p1_vel.y += dir1 * CONTROL_SPEED
				p2_vel.y += dir2 * CONTROL_SPEED
		else:
			# Move far vertically away from center Y
			var dir1 = signf(p1.global_position.y - center.y)
			var dir2 = signf(p2.global_position.y - center.y)
			if dir1 == 0:
				dir1 = -1.0
				dir2 = 1.0
			p1_vel.y += dir1 * CONTROL_SPEED
			p2_vel.y += dir2 * CONTROL_SPEED

	# 2. Circular rotation
	if _holding_rot_cw:
		var r1 = p1.global_position - center
		var r2 = p2.global_position - center
		if r1.length() > 5.0:
			var tangent1 = Vector2(-r1.y, r1.x).normalized()
			p1_vel += tangent1 * ROTATION_SPEED
		if r2.length() > 5.0:
			var tangent2 = Vector2(-r2.y, r2.x).normalized()
			p2_vel += tangent2 * ROTATION_SPEED

	if _holding_rot_ccw:
		var r1 = p1.global_position - center
		var r2 = p2.global_position - center
		if r1.length() > 5.0:
			var tangent1 = Vector2(r1.y, -r1.x).normalized()
			p1_vel += tangent1 * ROTATION_SPEED
		if r2.length() > 5.0:
			var tangent2 = Vector2(r2.y, -r2.x).normalized()
			p2_vel += tangent2 * ROTATION_SPEED

	# Apply extra velocity to players
	if "extra_velocity" in p1:
		p1.extra_velocity = p1_vel
	if "extra_velocity" in p2:
		p2.extra_velocity = p2_vel
