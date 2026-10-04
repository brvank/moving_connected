extends CanvasLayer

signal retry_pressed
signal home_pressed
signal next_level_pressed
signal level_select_pressed
signal pause_pressed
signal cancel_pressed

@onready var game_over_panel: PanelContainer = $Overlay/CenterContainer/GameOverPanel
@onready var level_complete_panel: PanelContainer = $Overlay/CenterContainer/LevelCompletePanel
@onready var pause_panel: PanelContainer = $Overlay/CenterContainer/PausePanel
@onready var pause_button: Button = $PauseButton
@onready var next_level_button: Button = $Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/NextLevelButton
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_dialogs()
	
	# Connect Pause button
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	
	# Connect Pause Panel buttons
	$Overlay/CenterContainer/PausePanel/VBoxContainer/ButtonsHBox/RestartButton.pressed.connect(_on_retry_pressed)
	$Overlay/CenterContainer/PausePanel/VBoxContainer/ButtonsHBox/HomeButton.pressed.connect(_on_home_pressed)
	$Overlay/CenterContainer/PausePanel/VBoxContainer/ButtonsHBox/CancelButton.pressed.connect(_on_cancel_pressed)
	$Overlay/CenterContainer/PausePanel/VBoxContainer/ButtonsHBox/LevelsButton.pressed.connect(_on_level_select_pressed)
	
	# Connect Game Over buttons
	$Overlay/CenterContainer/GameOverPanel/VBoxContainer/ButtonsHBox/RetryButton.pressed.connect(_on_retry_pressed)
	$Overlay/CenterContainer/GameOverPanel/VBoxContainer/ButtonsHBox/HomeButton.pressed.connect(_on_home_pressed)
	$Overlay/CenterContainer/GameOverPanel/VBoxContainer/ButtonsHBox/LevelsButton.pressed.connect(_on_level_select_pressed)
	
	# Connect Level Complete buttons
	next_level_button.pressed.connect(_on_next_level_pressed)
	$Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/RetryButton.pressed.connect(_on_retry_pressed)
	$Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/HomeButton.pressed.connect(_on_home_pressed)
	$Overlay/CenterContainer/LevelCompletePanel/VBoxContainer/ButtonsHBox/LevelsButton.pressed.connect(_on_level_select_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_paused():
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()
		elif not game_over_panel.visible and not level_complete_panel.visible:
			show_pause()
			get_viewport().set_input_as_handled()

func hide_dialogs() -> void:
	overlay.visible = false
	game_over_panel.visible = false
	level_complete_panel.visible = false
	if pause_panel:
		pause_panel.visible = false
	if pause_button:
		pause_button.visible = true

func is_paused() -> bool:
	return pause_panel != null and pause_panel.visible

func show_pause() -> void:
	if game_over_panel.visible or level_complete_panel.visible:
		return
	get_tree().paused = true
	overlay.visible = true
	pause_panel.visible = true
	game_over_panel.visible = false
	level_complete_panel.visible = false
	if pause_button:
		pause_button.visible = false
	pause_pressed.emit()

func resume_game() -> void:
	get_tree().paused = false
	hide_dialogs()
	cancel_pressed.emit()

func show_game_over() -> void:
	get_tree().paused = false
	overlay.visible = true
	game_over_panel.visible = true
	level_complete_panel.visible = false
	if pause_panel:
		pause_panel.visible = false
	if pause_button:
		pause_button.visible = false

func show_level_complete(has_next_level: bool = true) -> void:
	get_tree().paused = false
	overlay.visible = true
	level_complete_panel.visible = true
	game_over_panel.visible = false
	if pause_panel:
		pause_panel.visible = false
	if pause_button:
		pause_button.visible = false
	next_level_button.visible = has_next_level

func _on_pause_button_pressed() -> void:
	show_pause()

func _on_cancel_pressed() -> void:
	resume_game()

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _on_retry_pressed() -> void:
	get_tree().paused = false
	retry_pressed.emit()
	var gm = _get_game_manager()
	if gm:
		gm.restart_current_level()

func _on_home_pressed() -> void:
	get_tree().paused = false
	home_pressed.emit()
	var gm = _get_game_manager()
	if gm:
		gm.go_to_main_menu()

func _on_next_level_pressed() -> void:
	get_tree().paused = false
	next_level_pressed.emit()
	var gm = _get_game_manager()
	if gm:
		gm.load_next_level()

func _on_level_select_pressed() -> void:
	get_tree().paused = false
	level_select_pressed.emit()
	var gm = _get_game_manager()
	if gm:
		gm.go_to_level_select()
