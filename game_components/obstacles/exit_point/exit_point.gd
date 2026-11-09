extends Area2D

signal player_reached_exit(exit_point: Area2D, body: Node2D)
signal player_left_exit(exit_point: Area2D, body: Node2D)

@export var width: int = 50
@export var height: int = 50

var _occupants: Array[Node2D] = []
var _sprite: Sprite2D
var _anim_time: float = 0.0

func is_occupied() -> bool:
	return _occupants.size() > 0

func get_occupants() -> Array[Node2D]:
	return _occupants

func _ready() -> void:
	_sprite = $Sprite2D
	if _sprite:
		_sprite.visible = false

	var cs2d = $CollisionShape2D
	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_anim_time += delta * (6.0 if is_occupied() else 2.5)
	queue_redraw()

func _draw() -> void:
	var hw = width / 2.0
	var hh = height / 2.0
	var rect = Rect2(-hw, -hh, width, height)
	var occupied = is_occupied()

	# Colors
	var col_base = Color(0.03, 0.14, 0.16, 0.9) if not occupied else Color(0.04, 0.24, 0.28, 0.95)
	var col_border = Color(0.0, 1.0, 0.65, 0.9) if not occupied else Color(0.2, 1.0, 0.95, 1.0)
	var col_glow = Color(0.0, 1.0, 0.65, 0.35) if not occupied else Color(0.2, 1.0, 1.0, 0.55)

	# 1. Base hull
	draw_rect(rect, col_base, true)
	draw_rect(rect, col_border, false, 2.0)

	# 2. Tech corner brackets
	var blen = minf(width, height) * 0.25
	# Top-Left
	draw_line(Vector2(-hw, -hh + blen), Vector2(-hw, -hh), col_border, 2.5)
	draw_line(Vector2(-hw, -hh), Vector2(-hw + blen, -hh), col_border, 2.5)
	# Top-Right
	draw_line(Vector2(hw - blen, -hh), Vector2(hw, -hh), col_border, 2.5)
	draw_line(Vector2(hw, -hh), Vector2(hw, -hh + blen), col_border, 2.5)
	# Bottom-Right
	draw_line(Vector2(hw, hh - blen), Vector2(hw, hh), col_border, 2.5)
	draw_line(Vector2(hw, hh), Vector2(hw - blen, hh), col_border, 2.5)
	# Bottom-Left
	draw_line(Vector2(-hw + blen, hh), Vector2(-hw, hh), col_border, 2.5)
	draw_line(Vector2(-hw, hh), Vector2(-hw, hh - blen), col_border, 2.5)

	# 3. Concentric extraction rings
	var min_dim = minf(width, height)
	var r_outer = min_dim * 0.38
	var r_inner = min_dim * 0.22
	var pulse = sin(_anim_time) * 0.08

	draw_arc(Vector2.ZERO, r_outer * (1.0 + pulse), 0, TAU, 32, col_border, 1.8)
	draw_arc(Vector2.ZERO, r_inner, 0, TAU, 24, col_glow, 2.5)

	# 4. Central extraction core diamond
	var d_size = min_dim * (0.16 if not occupied else 0.22) * (1.0 + pulse * 1.5)
	var diamond = PackedVector2Array([
		Vector2(0, -d_size),
		Vector2(d_size, 0),
		Vector2(0, d_size),
		Vector2(-d_size, 0)
	])
	draw_colored_polygon(diamond, Color.WHITE if occupied else col_border)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body not in _occupants:
		_occupants.append(body)
		queue_redraw()
		player_reached_exit.emit(self, body)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_occupants.erase(body)
		queue_redraw()
		player_left_exit.emit(self, body)
