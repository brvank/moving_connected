extends Area2D

signal player_hit_danger(danger_zone: Area2D, body: Node2D)

@export_range(0, 1, 1) var movementDirection: int = 0
@export var width: int = 20
@export var height: int = 50
@export var movementDistance: float = 100.0
@export var movementDuration: float = 1.0

var _startPosition: Vector2
var _anim_time: float = 0.0

func _ready() -> void:
	var sprite2d = $Sprite2D
	if sprite2d:
		sprite2d.visible = false

	var cs2d = $CollisionShape2D
	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

	_startPosition = position
	_startMovement()

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_anim_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var hw = width / 2.0
	var hh = height / 2.0
	var rect = Rect2(-hw, -hh, width, height)

	var pulse = (sin(_anim_time) + 1.0) * 0.5
	var col_base = Color(0.85, 0.04, 0.14, 0.20 + pulse * 0.08)
	var col_border = Color(1.0, 0.12, 0.25, 0.85 + pulse * 0.15)
	var col_beam = Color(1.0, 0.20, 0.35, 0.35 + pulse * 0.2)

	# 1. Translucent Laser Plasma Field
	draw_rect(rect, col_base, true)

	# 2. Diagonal Laser Beam Lattice
	var beam_spacing = 16.0
	var total_span = width + height
	var start_diag = -hw - hh + fmod(_anim_time * 6.0, beam_spacing)
	var d = start_diag
	while d < start_diag + total_span + beam_spacing:
		var p1 = Vector2(clampf(d, -hw, hw), -hh)
		var p2 = Vector2(clampf(d - height, -hw, hw), hh)
		if p1 != p2:
			draw_line(p1, p2, col_beam, 1.2)
		d += beam_spacing

	# 3. Outer Laser Perimeter
	draw_rect(rect, col_border, false, 1.8)

	# 4. Corner Danger Brackets
	var blen = minf(width, height) * 0.3
	draw_line(Vector2(-hw, -hh + blen), Vector2(-hw, -hh), Color.WHITE, 2.0)
	draw_line(Vector2(-hw, -hh), Vector2(-hw + blen, -hh), Color.WHITE, 2.0)
	draw_line(Vector2(hw - blen, -hh), Vector2(hw, -hh), Color.WHITE, 2.0)
	draw_line(Vector2(hw, -hh), Vector2(hw, -hh + blen), Color.WHITE, 2.0)
	draw_line(Vector2(hw, hh - blen), Vector2(hw, hh), Color.WHITE, 2.0)
	draw_line(Vector2(hw, hh), Vector2(hw - blen, hh), Color.WHITE, 2.0)
	draw_line(Vector2(-hw + blen, hh), Vector2(-hw, hh), Color.WHITE, 2.0)
	draw_line(Vector2(-hw, hh), Vector2(-hw, hh - blen), Color.WHITE, 2.0)

	# 5. Motion direction indicators
	var arrow_size = minf(width, height) * 0.25
	var col_arrow = Color(1.0, 0.6, 0.6, 0.8)
	if movementDirection == 0:
		draw_line(Vector2(-arrow_size, -hh + 6.0), Vector2(0, -hh + 2.0), col_arrow, 1.8)
		draw_line(Vector2(0, -hh + 2.0), Vector2(arrow_size, -hh + 6.0), col_arrow, 1.8)
		draw_line(Vector2(-arrow_size, hh - 6.0), Vector2(0, hh - 2.0), col_arrow, 1.8)
		draw_line(Vector2(0, hh - 2.0), Vector2(arrow_size, hh - 6.0), col_arrow, 1.8)
	else:
		draw_line(Vector2(-hw + 6.0, -arrow_size), Vector2(-hw + 2.0, 0), col_arrow, 1.8)
		draw_line(Vector2(-hw + 2.0, 0), Vector2(-hw + 6.0, arrow_size), col_arrow, 1.8)
		draw_line(Vector2(hw - 6.0, -arrow_size), Vector2(hw - 2.0, 0), col_arrow, 1.8)
		draw_line(Vector2(hw - 2.0, 0), Vector2(hw - 6.0, arrow_size), col_arrow, 1.8)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_hit_danger.emit(self, body)

func _startMovement() -> void:
	var movementOffset: Vector2

	if movementDirection == 0:
		movementOffset = Vector2(0.0, movementDistance)
	else:
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
