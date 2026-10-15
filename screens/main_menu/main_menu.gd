extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/PlayButton
@onready var editor_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/EditorButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/ExitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	if editor_button:
		editor_button.pressed.connect(_on_editor_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.grab_focus()

func _on_play_pressed() -> void:
	GameManager.go_to_level_select()

func _on_editor_pressed() -> void:
	GameManager.go_to_level_editor()

func _on_exit_pressed() -> void:
	get_tree().quit()
