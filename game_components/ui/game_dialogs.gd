extends CanvasLayer

signal retry_pressed
signal home_pressed
signal next_level_pressed
signal level_select_pressed

@onready var game_over_panel: PanelContainer = $Overlay/CenterContainer/GameOverPanel
@onready var level_complete_panel: PanelContainer = $Overlay/CenterContainer/LevelCompletePanel
@onready var next_level_button: Button = $Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/NextLevelButton
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	hide_dialogs()
	
	# Connect Game Over buttons
	$Overlay/CenterContainer/GameOverPanel/VBoxContainer/ButtonsHBox/RetryButton.pressed.connect(_on_retry_pressed)
	$Overlay/CenterContainer/GameOverPanel/VBoxContainer/ButtonsHBox/HomeButton.pressed.connect(_on_home_pressed)
	$Overlay/CenterContainer/GameOverPanel/VBoxContainer/ButtonsHBox/LevelsButton.pressed.connect(_on_level_select_pressed)
	
	# Connect Level Complete buttons
	next_level_button.pressed.connect(_on_next_level_pressed)
	$Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/RetryButton.pressed.connect(_on_retry_pressed)
	$Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/HomeButton.pressed.connect(_on_home_pressed)
	$Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/LevelsButton.pressed.connect(_on_level_select_pressed)

func hide_dialogs() -> void:
	overlay.visible = false
	game_over_panel.visible = false
	level_complete_panel.visible = false

func show_game_over() -> void:
	overlay.visible = true
	game_over_panel.visible = true
	level_complete_panel.visible = false

func show_level_complete(has_next_level: bool = true) -> void:
	overlay.visible = true
	level_complete_panel.visible = true
	game_over_panel.visible = false
	next_level_button.visible = has_next_level

func _on_retry_pressed() -> void:
	retry_pressed.emit()
	GameManager.restart_current_level()

func _on_home_pressed() -> void:
	home_pressed.emit()
	GameManager.go_to_main_menu()

func _on_next_level_pressed() -> void:
	next_level_pressed.emit()
	GameManager.load_next_level()

func _on_level_select_pressed() -> void:
	level_select_pressed.emit()
	GameManager.go_to_level_select()
