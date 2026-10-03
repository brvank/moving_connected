extends Area2D

signal player_hit_danger(danger_zone: Area2D, body: Node2D)

@export_range(0, 1, 1) var movementDirection: int = 0
@export var width: int = 20
@export var height: int = 50
@export var movementDistance: float = 100.0
@export var movementDuration: float = 1.0

var _startPosition: Vector2

func _ready() -> void:
	var sprite2d = $Sprite2D
	var cs2d = $CollisionShape2D

	var texture2d = DrawableTexture2D.new()
	texture2d.setup(
		width, height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(1.0, 0.0, 0.0, 0.7)
	)
	sprite2d.texture = texture2d

	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

	_startPosition = position
	_startMovement()

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_hit_danger.emit(self, body)

func _startMovement() -> void:
	var movementOffset: Vector2

	if movementDirection == 0:
		# Vertical
		movementOffset = Vector2(0.0, movementDistance)
	else:
		# Horizontal
		movementOffset = Vector2(movementDistance, 0.0)

	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(
		self,
		"position",
		_startPosition + movementOffset,
		movementDuration
	)

	tween.tween_property(
		self,
		"position",
		_startPosition,
		movementDuration
	)
