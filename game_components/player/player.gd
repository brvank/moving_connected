extends CharacterBody2D

const SPEED = 300.0

@onready var sprite: Sprite2D = $Sprite2D
var _time: float = 0.0

func _ready() -> void:
	modulate = Color.WHITE

func _process(delta: float) -> void:
	# Subtle living quantum core breathing effect
	_time += delta * 4.0
	if sprite:
		var pulse = 1.0 + sin(_time) * 0.035
		sprite.scale = Vector2(0.25 * pulse, 0.25 * pulse)

func _physics_process(_delta: float) -> void:
	velocity = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized() * SPEED
	move_and_slide()
