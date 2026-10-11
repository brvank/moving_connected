extends CharacterBody2D

const SPEED = 300.0

var extra_velocity: Vector2 = Vector2.ZERO
var target_scale: float = 1.0

func _ready() -> void:
	add_to_group("players")

func _physics_process(delta: float) -> void:
	var base_velocity = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized() * SPEED
	velocity = base_velocity + extra_velocity
	move_and_slide()
	
	# Smoothly adjust scale toward target_scale
	if abs(scale.x - target_scale) > 0.005:
		var s = move_toward(scale.x, target_scale, delta * 4.0)
		scale = Vector2(s, s)
	else:
		scale = Vector2(target_scale, target_scale)

func set_target_scale(new_scale: float) -> void:
	target_scale = clampf(new_scale, 0.5, 2.0)

func reset_target_scale() -> void:
	target_scale = 1.0
