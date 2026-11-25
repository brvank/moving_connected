extends Area2D

signal player_reached_exit(exit_point: Area2D, body: Node2D)
signal player_left_exit(exit_point: Area2D, body: Node2D)

@export var width: int = 50
@export var height: int = 50

var _candidate_bodies: Array[Node2D] = []
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

func _physics_process(_delta: float) -> void:
	# Ensure all overlapping CharacterBody2D bodies are tracked
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and body not in _candidate_bodies:
			_candidate_bodies.append(body)

	# Clean up any invalidated candidate bodies
	var i = _candidate_bodies.size() - 1
	while i >= 0:
		var body = _candidate_bodies[i]
		if not is_instance_valid(body):
			_candidate_bodies.remove_at(i)
			if body in _occupants:
				_occupants.erase(body)
				queue_redraw()
		i -= 1

	# Check containment for all candidate bodies
	for body in _candidate_bodies:
		if not is_instance_valid(body):
			continue
		var inside = is_body_inside(body)
		if inside and body not in _occupants:
			_occupants.append(body)
			queue_redraw()
			player_reached_exit.emit(self, body)
		elif not inside and body in _occupants:
			_occupants.erase(body)
			queue_redraw()
			player_left_exit.emit(self, body)

func is_body_inside(body: Node2D) -> bool:
	if not is_instance_valid(body):
		return false

	var cs = body.get_node_or_null("CollisionShape2D")
	var cs_offset = cs.position if cs else Vector2.ZERO
	var body_center = body.global_position + cs_offset
	var body_size = _get_body_size(body)
	var body_half = body_size / 2.0

	var exit_half = Vector2(width, height) / 2.0
	var exit_rect = Rect2(global_position - exit_half, Vector2(width, height))
	var body_rect = Rect2(body_center - body_half, body_size)

	# Tolerance in pixels accommodates border stroke thickness and float imprecision
	const TOLERANCE: float = 3.0

	# If the exit area is large enough to contain the player's bounding box,
	# require the entire player body to be inside the exit area.
	# Otherwise (for smaller custom exit zones), require the player's center to be inside.
	if width >= body_size.x and height >= body_size.y:
		return exit_rect.grow(TOLERANCE).encloses(body_rect)
	else:
		return exit_rect.grow(TOLERANCE).has_point(body_center)

func _get_body_size(body: Node2D) -> Vector2:
	var cs = body.get_node_or_null("CollisionShape2D")
	if cs and cs.shape:
		if cs.shape is RectangleShape2D:
			return cs.shape.size
		elif cs.shape is CircleShape2D:
			return Vector2(cs.shape.radius * 2.0, cs.shape.radius * 2.0)
	return Vector2(32.0, 32.0)

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
	if body is CharacterBody2D and body not in _candidate_bodies:
		_candidate_bodies.append(body)
		if is_body_inside(body) and body not in _occupants:
			_occupants.append(body)
			queue_redraw()
			player_reached_exit.emit(self, body)

func _on_body_exited(body: Node2D) -> void:
	if body in _candidate_bodies:
		_candidate_bodies.erase(body)
	if body in _occupants:
		_occupants.erase(body)
		queue_redraw()
		player_left_exit.emit(self, body)
