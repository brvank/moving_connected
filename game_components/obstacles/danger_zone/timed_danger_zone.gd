extends Area2D

signal player_hit_danger(danger_zone: Area2D, body: Node2D)

@export var width: int = 20
@export var height: int = 50
@export var active_duration: float = 2.0
@export var inactive_duration: float = 2.0

var _is_active: bool = true
var _anim_time: float = 0.0

func _ready() -> void:
	var sprite2d = $Sprite2D
	if sprite2d:
		sprite2d.visible = false

	var cs2d = $CollisionShape2D
	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

	body_entered.connect(_on_body_entered)
	_start_timer_cycle()

func _process(delta: float) -> void:
	if _is_active:
		_anim_time += delta * 4.0
		queue_redraw()

func _draw() -> void:
	var hw = width / 2.0
	var hh = height / 2.0
	var rect = Rect2(-hw, -hh, width, height)

	if _is_active:
		var pulse = (sin(_anim_time) + 1.0) * 0.5
		var col_base = Color(0.85, 0.04, 0.14, 0.22 + pulse * 0.1)
		var col_border = Color(1.0, 0.12, 0.25, 0.85 + pulse * 0.15)
		var col_beam = Color(1.0, 0.20, 0.35, 0.40 + pulse * 0.2)

		# 1. Active Translucent Laser Plasma Field
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
	else:
		# Inactive Cooling Stasis State (safe)
		var col_inactive_base = Color(0.1, 0.15, 0.25, 0.1)
		var col_inactive_border = Color(0.3, 0.55, 0.75, 0.4)
		draw_rect(rect, col_inactive_base, true)
		draw_rect(rect, col_inactive_border, false, 1.0)
		# Central stasis indicator dot
		draw_circle(Vector2.ZERO, 3.0, col_inactive_border)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and _is_active:
		player_hit_danger.emit(self, body)

func _start_timer_cycle() -> void:
	while is_inside_tree():
		# Active phase — dangerous
		_is_active = true
		monitoring = true
		queue_redraw()
		await get_tree().create_timer(active_duration).timeout
		if not is_inside_tree():
			break
		# Inactive phase — safe to pass
		_is_active = false
		monitoring = false
		queue_redraw()
		await get_tree().create_timer(inactive_duration).timeout
