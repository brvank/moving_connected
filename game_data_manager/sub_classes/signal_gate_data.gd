class_name SignalGateData

var block_position: Vector2
var switch_position: Vector2
var block_width: int = 20
var block_height: int = 50
var switch_width: int = 20
var switch_height: int = 20

func _init(block_pos: Vector2, switch_pos: Vector2, b_w: int = 20, b_h: int = 50, s_w: int = 20, s_h: int = 20):
	block_position = block_pos
	switch_position = switch_pos
	block_width = b_w
	block_height = b_h
	switch_width = s_w
	switch_height = s_h
