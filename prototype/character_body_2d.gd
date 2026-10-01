extends CharacterBody2D

const SPEED = 300.0
const DAMPING_SPEED = 10.0
const SPEED_SCALE = 50

func _physics_process(delta: float) -> void:
	velocity = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized() * delta * SPEED_SCALE * SPEED
	move_and_slide()
