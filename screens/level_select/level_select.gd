extends Control

@onready var back_button: Button = %BackButton
@onready var tab_world_1: Button = %TabWorld1
@onready var tab_world_2: Button = %TabWorld2
@onready var tab_world_3: Button = %TabWorld3

@onready var world_title_label: Label = %WorldTitleLabel
@onready var world_reward_label: Label = %WorldRewardLabel
@onready var level_grid: HFlowContainer = %LevelGrid

var _current_world: int = 1

# Card StyleBoxes
var _style_blue_normal: StyleBoxFlat
var _style_blue_hover: StyleBoxFlat
var _style_red_normal: StyleBoxFlat
var _style_red_hover: StyleBoxFlat
var _style_locked: StyleBoxFlat
var _style_tab_active: StyleBoxFlat
var _style_tab_inactive: StyleBoxFlat

func _ready() -> void:
	_init_styles()

	back_button.pressed.connect(_on_back_pressed)
	tab_world_1.pressed.connect(func(): _select_world(1))
	tab_world_2.pressed.connect(func(): _select_world(2))
	tab_world_3.pressed.connect(func(): _select_world(3))

	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		_current_world = gm.current_world

	_select_world(_current_world)

func _init_styles() -> void:
	# Blue card (Easy/Medium 1-8)
	_style_blue_normal = StyleBoxFlat.new()
	_style_blue_normal.bg_color = Color(0.12, 0.22, 0.38, 0.88)
	_style_blue_normal.border_color = Color(0.28, 0.6, 0.98, 0.9)
	_style_blue_normal.set_border_width_all(2)
	_style_blue_normal.set_corner_radius_all(10)
	_style_blue_normal.content_margin_left = 12
	_style_blue_normal.content_margin_right = 12
	_style_blue_normal.content_margin_top = 10
	_style_blue_normal.content_margin_bottom = 10

	_style_blue_hover = _style_blue_normal.duplicate()
	_style_blue_hover.bg_color = Color(0.18, 0.32, 0.54, 1.0)
	_style_blue_hover.border_color = Color(0.5, 0.8, 1.0, 1.0)

	# Red card (Hard 9-11)
	_style_red_normal = StyleBoxFlat.new()
	_style_red_normal.bg_color = Color(0.38, 0.12, 0.16, 0.92)
	_style_red_normal.border_color = Color(0.95, 0.3, 0.36, 0.95)
	_style_red_normal.set_border_width_all(2)
	_style_red_normal.set_corner_radius_all(10)
	_style_red_normal.content_margin_left = 12
	_style_red_normal.content_margin_right = 12
	_style_red_normal.content_margin_top = 10
	_style_red_normal.content_margin_bottom = 10

	_style_red_hover = _style_red_normal.duplicate()
	_style_red_hover.bg_color = Color(0.52, 0.16, 0.22, 1.0)
	_style_red_hover.border_color = Color(1.0, 0.5, 0.55, 1.0)

	# Locked card
	_style_locked = StyleBoxFlat.new()
	_style_locked.bg_color = Color(0.11, 0.12, 0.16, 0.6)
	_style_locked.border_color = Color(0.22, 0.24, 0.3, 0.45)
	_style_locked.set_border_width_all(1)
	_style_locked.set_corner_radius_all(10)
	_style_locked.content_margin_left = 12
	_style_locked.content_margin_right = 12
	_style_locked.content_margin_top = 10
	_style_locked.content_margin_bottom = 10

	# Tab styles
	_style_tab_active = StyleBoxFlat.new()
	_style_tab_active.bg_color = Color(0.25, 0.45, 0.85, 0.95)
	_style_tab_active.set_corner_radius_all(8)
	_style_tab_active.content_margin_left = 18
	_style_tab_active.content_margin_right = 18
	_style_tab_active.content_margin_top = 10
	_style_tab_active.content_margin_bottom = 10

	_style_tab_inactive = StyleBoxFlat.new()
	_style_tab_inactive.bg_color = Color(0.14, 0.16, 0.24, 0.7)
	_style_tab_inactive.set_corner_radius_all(8)
	_style_tab_inactive.content_margin_left = 18
	_style_tab_inactive.content_margin_right = 18
	_style_tab_inactive.content_margin_top = 10
	_style_tab_inactive.content_margin_bottom = 10

func _select_world(world: int) -> void:
	_current_world = world
	_update_tabs()
	_update_header()
	_populate_levels()

func _update_tabs() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var w2_unlocked = (gm == null or gm.is_world_unlocked(2))
	var w3_unlocked = (gm == null or gm.is_world_unlocked(3))

	tab_world_1.add_theme_stylebox_override("normal", _style_tab_active if _current_world == 1 else _style_tab_inactive)
	tab_world_2.add_theme_stylebox_override("normal", _style_tab_active if _current_world == 2 else _style_tab_inactive)
	tab_world_3.add_theme_stylebox_override("normal", _style_tab_active if _current_world == 3 else _style_tab_inactive)

	tab_world_1.text = "World 1: Fixed & Shifting"
	tab_world_2.text = "World 2: Gates & Hazards" if w2_unlocked else "World 2: 🔒 Locked"
	tab_world_3.text = "World 3: Timed & Dynamic" if w3_unlocked else "World 3: 🔒 Locked"

func _update_header() -> void:
	var gm = get_node_or_null("/root/GameManager")
	match _current_world:
		1:
			world_title_label.text = "World 1 — Fixed & Shifting Blocks"
			var sep_status = "✓ UNLOCKED" if (gm != null and gm.has_separators_unlocked()) else "Clear 1-8"
			var rot_status = "✓ UNLOCKED" if (gm != null and gm.has_circular_unlocked()) else "Clear 1-11"
			world_reward_label.text = "🏆 Awards: Separators [⇄] (%s) | Circular Rotation [↻] (%s)" % [sep_status, rot_status]
		2:
			world_title_label.text = "World 2 — Signal Gates & Fixed Danger Zones"
			var size_status = "✓ UNLOCKED" if (gm != null and gm.has_size_changer_unlocked()) else "Clear 2-8"
			world_reward_label.text = "🏆 Awards: Size Changer [⇱] (%s)" % size_status
		3:
			world_title_label.text = "World 3 — Timed & Shifting Danger Zones"
			world_reward_label.text = "★ Master Gauntlet: Extreme synchronized puzzles using all controls"

func _populate_levels() -> void:
	# Clear old level buttons
	for child in level_grid.get_children():
		child.queue_free()

	var gm = get_node_or_null("/root/GameManager")
	var is_world_unlocked = (gm == null or gm.is_world_unlocked(_current_world))

	# 11 levels per world
	for l in range(1, 12):
		var is_hard = (l >= 9)
		var is_unlocked = is_world_unlocked and (gm == null or gm.is_level_unlocked(_current_world, l))
		var is_completed = (gm != null and gm.is_level_completed(_current_world, l))

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(170, 100)
		btn.disabled = not is_unlocked

		# Apply Blue (Easy/Medium 1-8) or Red (Hard 9-11) styles
		if not is_unlocked:
			btn.add_theme_stylebox_override("normal", _style_locked)
			btn.add_theme_stylebox_override("disabled", _style_locked)
			btn.text = "Level %d-%d\n🔒 Locked" % [_current_world, l]
			btn.modulate = Color(0.7, 0.7, 0.7, 0.75)
		else:
			if is_hard:
				btn.add_theme_stylebox_override("normal", _style_red_normal)
				btn.add_theme_stylebox_override("hover", _style_red_hover)
				btn.add_theme_stylebox_override("pressed", _style_red_hover)
				if is_completed:
					btn.text = "Level %d-%d ✓\n★ HARD ★\n(Completed)" % [_current_world, l]
				else:
					btn.text = "Level %d-%d\n★ HARD ★\n(3x Arena)" % [_current_world, l]
			else:
				btn.add_theme_stylebox_override("normal", _style_blue_normal)
				btn.add_theme_stylebox_override("hover", _style_blue_hover)
				btn.add_theme_stylebox_override("pressed", _style_blue_hover)
				var tag = "Easy" if l <= 4 else "Medium"
				if is_completed:
					btn.text = "Level %d-%d ✓\n(%s Completed)" % [_current_world, l, tag]
				else:
					btn.text = "Level %d-%d\n(%s Puzzle)" % [_current_world, l, tag]
			btn.modulate = Color.WHITE

		var level_num = l
		btn.pressed.connect(func(): _on_level_selected(_current_world, level_num))
		level_grid.add_child(btn)

func _on_level_selected(world: int, level: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		if not gm.is_level_unlocked(world, level):
			return
		gm.load_level(world, level)

func _on_back_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
