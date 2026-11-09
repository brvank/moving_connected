extends StaticBody2D

@export_range(0, 1, 1) var movementDirection: int = 0

@export var width = 20
@export var height = 50
@export var movementDistance: float = 100.0
@export var movementDuration: float = 1.0

var _startPosition: Vector2

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

func _draw() -> void:
	var hw = width / 2.0
	var hh = height / 2.0
	var rect = Rect2(-hw, -hh, width, height)

	# Colors
	var col_base = Color(0.12, 0.09, 0.04, 1.0)
	var col_border = Color(1.0, 0.68, 0.12, 0.95)
	var col_stripe = Color(1.0, 0.75, 0.2, 0.4)
	var col_core = Color(1.0, 0.9, 0.4, 0.9)

	# 1. Dark chassis base
	draw_rect(rect, col_base, true)

	# 2. Diagonal kinetic hazard stripes
	var stripe_w = 14.0
	var total_span = width + height
	var start_diag = -hw - hh
	var d = start_diag
	while d < start_diag + total_span + stripe_w:
		# Draw angled stripe across bounding rect
		var p1 = Vector2(d, -hh)
		var p2 = Vector2(d - height, hh)
		# Clamp points within rect
		draw_line(
			Vector2(clampf(p1.x, -hw, hw), -hh),
			Vector2(clampf(p2.x, -hw, hw), hh),
			col_stripe,
			4.0
		)
		d += stripe_w

	# 3. Kinetic amber border
	draw_rect(rect, col_border, false, 2.0)

	# 4. Movement direction chevron indicators
	var arrow_size = minf(width, height) * 0.25
	if movementDirection == 0:
		# Vertical motion chevrons (Up & Down)
		draw_line(Vector2(-arrow_size, -hh + 8.0), Vector2(0, -hh + 3.0), col_core, 2.0)
		draw_line(Vector2(0, -hh + 3.0), Vector2(arrow_size, -hh + 8.0), col_core, 2.0)
		draw_line(Vector2(-arrow_size, hh - 8.0), Vector2(0, hh - 3.0), col_core, 2.0)
		draw_line(Vector2(0, hh - 3.0), Vector2(arrow_size, hh - 8.0), col_core, 2.0)
	else:
		# Horizontal motion chevrons (Left & Right)
		draw_line(Vector2(-hw + 8.0, -arrow_size), Vector2(-hw + 3.0, 0), col_core, 2.0)
		draw_line(Vector2(-hw + 3.0, 0), Vector2(-hw + 8.0, arrow_size), col_core, 2.0)
		draw_line(Vector2(hw - 8.0, -arrow_size), Vector2(hw - 3.0, 0), col_core, 2.0)
		draw_line(Vector2(hw - 3.0, 0), Vector2(hw - 8.0, arrow_size), col_core, 2.0)

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
