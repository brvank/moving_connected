class_name SinglePointPosition

var _position: Vector2
var shiftingDirection: int = 0 #for moving blocks

func _init(pos: Vector2, shifting_direction:int = 0):
	_position = pos
	shiftingDirection = shifting_direction
	pass

func getX() -> float:
	return _position.x

func getY() -> float:
	return _position.y

func position() -> Vector2:
	return _position
