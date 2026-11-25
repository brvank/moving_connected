extends CharacterBody2D

const SPEED = 300.0

func _physics_process(_delta: float) -> void:
	var move_input := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if move_input.length_squared() > 1.0:
		move_input = move_input.normalized()
	var speed_mult := 1.0
	if get_node_or_null("/root/GameManager") != null:
		speed_mult = GameManager.player_speed_multiplier
	velocity = move_input * (SPEED * speed_mult)
	move_and_slide()
