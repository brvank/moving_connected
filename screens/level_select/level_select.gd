extends Control

@onready var back_button: Button = $VBoxContainer/TopBar/BackButton
@onready var content_vbox: VBoxContainer = $VBoxContainer/ScrollContainer/ContentVBox

const NUM_WORLDS: int = 4
const LEVELS_PER_WORLD: int = 10

const WORLD_INFO := [
	{"title": "World 1 — Blocks", "color": Color(0.5, 0.8, 1, 1), "desc": "Fixed & shifting blocks"},
	{"title": "World 2 — Danger Zones", "color": Color(1, 0.7, 0.4, 1), "desc": "Fixed & shifting hazards"},
	{"title": "World 3 — Timed Hazards", "color": Color(1, 0.5, 0.6, 1), "desc": "Timed danger zones"},
	{"title": "World 4 — Signal Gates", "color": Color(0.7, 0.5, 1, 1), "desc": "Cooperative gates"},
]

var _level_buttons: Dictionary = {}  # "w_l" -> Button
var _world_headers: Dictionary = {}  # world -> Label

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_ui()
	_update_ui()

func _build_ui() -> void:
	for world in range(1, NUM_WORLDS + 1):
		var info = WORLD_INFO[world - 1]

		var section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 12)
		content_vbox.add_child(section)

		var header = Label.new()
		header.add_theme_color_override("font_color", info.color)
		header.add_theme_font_size_override("font_size", 22)
		header.text = info.title
		section.add_child(header)
		_world_headers[world] = header

		var grid = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 20)
		section.add_child(grid)

		for level in range(1, LEVELS_PER_WORLD + 1):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(140, 100)
			btn.add_theme_font_size_override("font_size", 18)
			btn.add_theme_stylebox_override("normal", _style_card())
			btn.add_theme_stylebox_override("hover", _style_card_hover())
			btn.add_theme_stylebox_override("pressed", _style_card_hover())
			btn.add_theme_stylebox_override("disabled", _style_card_disabled())
			btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.53, 0.62, 0.7))
			grid.add_child(btn)
			btn.pressed.connect(_on_level_selected.bind(world, level))
			_level_buttons["%d_%d" % [world, level]] = btn

func _style_card() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.2, 0.28, 0.9)
	s.set_corner_radius_all(10)
	s.set_border_width_all(1)
	s.border_color = Color(0.3, 0.35, 0.5, 0.6)
	return s

func _style_card_hover() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.28, 0.32, 0.46, 1)
	s.set_corner_radius_all(10)
	s.set_border_width_all(2)
	s.border_color = Color(0.55, 0.6, 0.9, 1)
	return s

func _style_card_disabled() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.13, 0.18, 0.6)
	s.set_corner_radius_all(10)
	s.set_border_width_all(1)
	s.border_color = Color(0.2, 0.22, 0.3, 0.4)
	return s

func _update_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")

	for world in range(1, NUM_WORLDS + 1):
		var header: Label = _world_headers.get(world)
		if header:
			var info = WORLD_INFO[world - 1]
			var is_unlocked: bool = (gm == null or gm.is_world_unlocked(world))
			if is_unlocked:
				header.text = info.title
				header.modulate = Color.WHITE
			else:
				header.text = info.title + "  🔒"
				header.modulate = Color(0.65, 0.65, 0.65, 0.8)

		for level in range(1, LEVELS_PER_WORLD + 1):
			var btn: Button = _level_buttons.get("%d_%d" % [world, level])
			if btn == null:
				continue
			var lvl_unlocked: bool = (gm == null or gm.is_level_unlocked(world, level))
			var is_completed: bool = (gm != null and gm.is_level_completed(world, level))
			var title = "Level %d-%d" % [world, level]

			btn.disabled = not lvl_unlocked
			if not lvl_unlocked:
				btn.text = "%s\n🔒 Locked" % title
				btn.modulate = Color(0.7, 0.7, 0.7, 0.75)
			elif is_completed:
				btn.text = "%s ✓" % title
				btn.modulate = Color.WHITE
			else:
				btn.text = title
				btn.modulate = Color.WHITE

func _on_level_selected(world: int, level: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and not gm.is_level_unlocked(world, level):
		print("LevelSelect: Level %d-%d is locked" % [world, level])
		return
	print("Level selected: World %d, Level %d" % [world, level])
	if gm != null:
		gm.load_level(world, level)

func _on_back_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
