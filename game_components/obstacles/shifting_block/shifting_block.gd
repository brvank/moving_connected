extends StaticBody2D

@export_range(0, 1, 1) var movementDirection: int = 0

@export var width = 20
@export var height = 50
@export var movementDistance: float = 100.0
@export var movementDuration: float = 1.0

var _startPosition: Vector2

func _ready() -> void:
		
	var sprite2d = $Sprite2D
	var cs2d = $CollisionShape2D
	
	var texture2d = DrawableTexture2D.new()
	texture2d.setup(
		width, 
		height, 
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, 
		Color(1.0, 0.502, 0.051, 1.0)
	)
	sprite2d.texture = texture2d
	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height, )
	cs2d.shape = rShape2d
	_startPosition = position
	_startMovement()

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
