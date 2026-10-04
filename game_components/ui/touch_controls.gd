extends CanvasLayer

## On-screen directional touch controls.
## Uses regular Control buttons that inject ui_left/right/up/down
## input actions on press/release so the Player script works unchanged.

@onready var btn_left: Button = %BtnLeft
@onready var btn_right: Button = %BtnRight
@onready var btn_up: Button = %BtnUp
@onready var btn_down: Button = %BtnDown

func _ready() -> void:
	_connect_button(btn_left, "ui_left")
	_connect_button(btn_right, "ui_right")
	_connect_button(btn_up, "ui_up")
	_connect_button(btn_down, "ui_down")

func _connect_button(btn: Button, action: StringName) -> void:
	btn.button_down.connect(func(): Input.action_press(action))
	btn.button_up.connect(func(): Input.action_release(action))
