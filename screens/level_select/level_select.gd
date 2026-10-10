extends Control

@onready var back_button: Button = $VBoxContainer/TopBar/BackButton

@onready var btn_1_1: Button = $VBoxContainer/ScrollContainer/ContentVBox/World1Section/GridContainer/Level_1_1
@onready var btn_1_2: Button = $VBoxContainer/ScrollContainer/ContentVBox/World1Section/GridContainer/Level_1_2
@onready var btn_2_1: Button = $VBoxContainer/ScrollContainer/ContentVBox/World2Section/GridContainer/Level_2_1
@onready var btn_2_2: Button = $VBoxContainer/ScrollContainer/ContentVBox/World2Section/GridContainer/Level_2_2

@onready var world1_header: Label = $VBoxContainer/ScrollContainer/ContentVBox/World1Section/World1Header
@onready var world2_header: Label = $VBoxContainer/ScrollContainer/ContentVBox/World2Section/World2Header

const LEVEL_CONFIG = [
	{
		"world": 1,
		"level": 1,
		"title": "Level 1-1",
		"desc": "(2 Players)",
		"node_path": "VBoxContainer/ScrollContainer/ContentVBox/World1Section/GridContainer/Level_1_1"
	},
	{
		"world": 1,
		"level": 2,
		"title": "Level 1-2",
		"desc": "(Gates & Hazard)",
		"node_path": "VBoxContainer/ScrollContainer/ContentVBox/World1Section/GridContainer/Level_1_2"
	},
	{
		"world": 2,
		"level": 1,
		"title": "Level 2-1",
		"desc": "(3 Players)",
		"node_path": "VBoxContainer/ScrollContainer/ContentVBox/World2Section/GridContainer/Level_2_1"
	},
	{
		"world": 2,
		"level": 2,
		"title": "Level 2-2",
		"desc": "(Cross Gates)",
		"node_path": "VBoxContainer/ScrollContainer/ContentVBox/World2Section/GridContainer/Level_2_2"
	}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	btn_1_1.pressed.connect(func(): _on_level_selected(1, 1))
	btn_1_2.pressed.connect(func(): _on_level_selected(1, 2))
	btn_2_1.pressed.connect(func(): _on_level_selected(2, 1))
	btn_2_2.pressed.connect(func(): _on_level_selected(2, 2))
	
	_update_ui()

func _update_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	
	# World 2 header lock status
	if world2_header:
		var is_w2_unlocked: bool = (gm == null or gm.is_world_unlocked(2))
		if is_w2_unlocked:
			world2_header.text = "World 2 — Triad Dynamics"
			world2_header.modulate = Color.WHITE
		else:
			world2_header.text = "World 2 — Triad Dynamics  🔒"
			world2_header.modulate = Color(0.65, 0.65, 0.65, 0.8)

	# Update level buttons
	for cfg in LEVEL_CONFIG:
		var btn: Button = get_node_or_null(cfg.node_path)
		if btn == null:
			continue
		
		var w: int = cfg.world
		var l: int = cfg.level
		var is_unlocked: bool = (gm == null or gm.is_level_unlocked(w, l))
		var is_completed: bool = (gm != null and gm.is_level_completed(w, l))
		
		btn.disabled = not is_unlocked
		
		if not is_unlocked:
			btn.text = "%s\n🔒 Locked" % cfg.title
			btn.modulate = Color(0.7, 0.7, 0.7, 0.75)
		elif is_completed:
			btn.text = "%s ✓\n%s" % [cfg.title, cfg.desc]
			btn.modulate = Color.WHITE
		else:
			btn.text = "%s\n%s" % [cfg.title, cfg.desc]
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
