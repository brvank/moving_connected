extends CharacterBody2D

const SPEED = 300.0

func _ready() -> void:
	# Holographic cyber drone tint
	modulate = Color(0.2, 0.9, 1.0, 1.0)

func _physics_process(_delta: float) -> void:
	velocity = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized() * SPEED
	move_and_slide()
