extends Control

@onready var back_button: Button = $VBoxContainer/TopBar/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect level selection buttons
	# World 1
	var btn_1_1 = $VBoxContainer/ScrollContainer/ContentVBox/World1Section/GridContainer/Level_1_1
	var btn_1_2 = $VBoxContainer/ScrollContainer/ContentVBox/World1Section/GridContainer/Level_1_2
	btn_1_1.pressed.connect(func(): _on_level_selected(1, 1))
	btn_1_2.pressed.connect(func(): _on_level_selected(1, 2))
	
	# World 2
	var btn_2_1 = $VBoxContainer/ScrollContainer/ContentVBox/World2Section/GridContainer/Level_2_1
	var btn_2_2 = $VBoxContainer/ScrollContainer/ContentVBox/World2Section/GridContainer/Level_2_2
	btn_2_1.pressed.connect(func(): _on_level_selected(2, 1))
	btn_2_2.pressed.connect(func(): _on_level_selected(2, 2))

func _on_level_selected(world: int, level: int) -> void:
	print("Level selected: World %d, Level %d" % [world, level])
	GameManager.load_level(world, level)

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
