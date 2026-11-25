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
	var move_input := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if move_input.length_squared() > 1.0:
		move_input = move_input.normalized()
	var speed_mult := 1.0
	if get_node_or_null("/root/GameManager") != null:
		speed_mult = GameManager.player_speed_multiplier
	velocity = move_input * (SPEED * speed_mult)
	move_and_slide()
