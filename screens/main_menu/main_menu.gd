extends Control

const ICON_MUSIC_ON = preload("res://assets/icons/music_on.svg")
const ICON_MUSIC_OFF = preload("res://assets/icons/music_off.svg")
const ICON_SFX_ON = preload("res://assets/icons/sfx_on.svg")
const ICON_SFX_OFF = preload("res://assets/icons/sfx_off.svg")

@onready var play_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/PlayButton
@onready var editor_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/EditorButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/ExitButton
@onready var bgm_toggle_button: Button = $AudioControls/BgmToggleButton
@onready var sfx_toggle_button: Button = $AudioControls/SfxToggleButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	if editor_button:
		editor_button.pressed.connect(_on_editor_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.grab_focus()

	# Audio Toggle Buttons
	if bgm_toggle_button:
		bgm_toggle_button.pressed.connect(_on_bgm_toggle_pressed)
		_update_bgm_button(SoundManager.is_bgm_muted)
		SoundManager.bgm_toggled.connect(_update_bgm_button)

	if sfx_toggle_button:
		sfx_toggle_button.pressed.connect(_on_sfx_toggle_pressed)
		_update_sfx_button(SoundManager.is_sfx_muted)
		SoundManager.sfx_toggled.connect(_update_sfx_button)

func _on_play_pressed() -> void:
	GameManager.go_to_level_select()

func _on_editor_pressed() -> void:
	GameManager.go_to_level_editor()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_bgm_toggle_pressed() -> void:
	SoundManager.toggle_bgm()

func _on_sfx_toggle_pressed() -> void:
	SoundManager.toggle_sfx()

func _update_bgm_button(is_muted: bool) -> void:
	if not bgm_toggle_button:
		return
	bgm_toggle_button.icon = ICON_MUSIC_OFF if is_muted else ICON_MUSIC_ON
	bgm_toggle_button.tooltip_text = "Music: MUTED (Click to Unmute)" if is_muted else "Music: ACTIVE (Click to Mute)"
	bgm_toggle_button.modulate = Color(0.65, 0.7, 0.8, 0.75) if is_muted else Color(1.0, 1.0, 1.0, 1.0)

func _update_sfx_button(is_muted: bool) -> void:
	if not sfx_toggle_button:
		return
	sfx_toggle_button.icon = ICON_SFX_OFF if is_muted else ICON_SFX_ON
	sfx_toggle_button.tooltip_text = "SFX: MUTED (Click to Unmute)" if is_muted else "SFX: ACTIVE (Click to Mute)"
	sfx_toggle_button.modulate = Color(0.65, 0.7, 0.8, 0.75) if is_muted else Color(1.0, 1.0, 1.0, 1.0)
