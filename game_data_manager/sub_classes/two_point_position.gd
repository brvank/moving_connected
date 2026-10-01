class_name TwoPointPosition

var left : float
var top : float
var right : float
var bottom : float

func _init(left_top: Vector2, right_bottom: Vector2):
	left = left_top.x
	top = left_top.y
	right = right_bottom.x
	bottom = right_bottom.y
