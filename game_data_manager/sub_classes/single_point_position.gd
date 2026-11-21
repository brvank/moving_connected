class_name SinglePointPosition

var _position: Vector2
var shiftingDirection: int = 0 #for moving blocks
var width: int = 20
var height: int = 50
var movementDistance: float = 100.0  # pixel travel distance for shifting obstacles

func _init(pos: Vector2, shifting_direction: int = 0, w: int = 20, h: int = 50, move_dist: float = 100.0):
	_position = pos
	shiftingDirection = shifting_direction
	width = w
	height = h
	movementDistance = move_dist
	pass

func getX() -> float:
	return _position.x

func getY() -> float:
	return _position.y

func position() -> Vector2:
	return _position
