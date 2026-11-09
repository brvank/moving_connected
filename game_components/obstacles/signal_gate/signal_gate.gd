extends Node2D

@export var block_width: int = 20
@export var block_height: int = 50
@export var switch_width: int = 20
@export var switch_height: int = 20

var block_position: Vector2
var switch_position: Vector2

var _overlap_count: int = 0
var _is_open: bool = false
var _block_collision: CollisionShape2D

var _gate_visual: Node2D
var _switch_visual: Node2D

# ── Gate Forcefield Visual ───────────────────────────────────────────────────

class GateForcefieldVisual extends Node2D:
	var width: float
	var height: float
	var is_open: bool = false
	var anim_time: float = 0.0

	func _process(delta: float) -> void:
		if not is_open:
			anim_time += delta * 5.0
			queue_redraw()

	func _draw() -> void:
		var hw = width / 2.0
		var hh = height / 2.0
		var rect = Rect2(-hw, -hh, width, height)

		if not is_open:
			# Active Violet Quantum Forcefield
			var pulse = (sin(anim_time) + 1.0) * 0.5
			var col_field = Color(0.75, 0.15, 1.0, 0.35 + pulse * 0.15)
			var col_border = Color(0.85, 0.30, 1.0, 0.9 + pulse * 0.1)
			var col_beam = Color(0.95, 0.60, 1.0, 0.7)

			# Forcefield Plasma Body
			draw_rect(rect, col_field, true)
			draw_rect(rect, col_border, false, 2.0)

			# Central Plasma Conduit Beam
			if width > height:
				draw_line(Vector2(-hw + 4, 0), Vector2(hw - 4, 0), col_beam, 2.0)
			else:
				draw_line(Vector2(0, -hh + 4), Vector2(0, hh - 4), col_beam, 2.0)

			# Emitter Nodes at ends
			var r_dot = minf(width, height) * 0.22
			draw_circle(Vector2(-hw + r_dot + 2, -hh + r_dot + 2), r_dot, col_border)
			draw_circle(Vector2(hw - r_dot - 2, hh - r_dot - 2), r_dot, col_border)
		else:
			# De-energized Stasis Field (Permeable)
			var col_open_field = Color(0.65, 0.2, 0.9, 0.08)
			var col_open_border = Color(0.0, 0.8, 1.0, 0.35)
			draw_rect(rect, col_open_field, true)
			draw_rect(rect, col_open_border, false, 1.0)

# ── Terminal Switch Visual ────────────────────────────────────────────────────

class SwitchTerminalVisual extends Node2D:
	var width: float
	var height: float
	var is_active: bool = false
	var anim_time: float = 0.0

	func _process(delta: float) -> void:
		if is_active:
			anim_time += delta * 6.0
			queue_redraw()

	func _draw() -> void:
		var hw = width / 2.0
		var hh = height / 2.0
		var rect = Rect2(-hw, -hh, width, height)

		var col_plate = Color(0.04, 0.12, 0.20, 0.95) if not is_active else Color(0.06, 0.22, 0.28, 0.95)
		var col_border = Color(0.0, 0.85, 0.75, 0.85) if not is_active else Color(0.3, 1.0, 0.95, 1.0)
		var col_core = Color(0.0, 0.95, 0.85, 0.9) if not is_active else Color.WHITE

		# Base Terminal Plate
		draw_rect(rect, col_plate, true)
		draw_rect(rect, col_border, false, 1.8)

		# Central Quantum Switch Glyph
		var d = minf(width, height) * 0.3
		var diamond = PackedVector2Array([
			Vector2(0, -d),
			Vector2(d, 0),
			Vector2(0, d),
			Vector2(-d, 0)
		])
		draw_colored_polygon(diamond, col_core)

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# 1. Gate Block (StaticBody2D at block_position)
	var block = StaticBody2D.new()
	block.position = block_position

	_gate_visual = GateForcefieldVisual.new()
	_gate_visual.width = float(block_width)
	_gate_visual.height = float(block_height)
	block.add_child(_gate_visual)

	_block_collision = CollisionShape2D.new()
	var blockShape = RectangleShape2D.new()
	blockShape.size = Vector2(block_width, block_height)
	_block_collision.shape = blockShape
	block.add_child(_block_collision)

	add_child(block)

	# 2. Switch (Area2D at switch_position)
	var switch_area = Area2D.new()
	switch_area.position = switch_position

	_switch_visual = SwitchTerminalVisual.new()
	_switch_visual.width = float(switch_width)
	_switch_visual.height = float(switch_height)
	switch_area.add_child(_switch_visual)

	var switchCollision = CollisionShape2D.new()
	var switchShape = RectangleShape2D.new()
	switchShape.size = Vector2(switch_width, switch_height)
	switchCollision.shape = switchShape
	switch_area.add_child(switchCollision)

	switch_area.body_entered.connect(_on_switch_body_entered)
	switch_area.body_exited.connect(_on_switch_body_exited)

	add_child(switch_area)

func _on_switch_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_overlap_count += 1
		_update_gate_state()

func _on_switch_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_overlap_count = max(0, _overlap_count - 1)
		_update_gate_state()

func _update_gate_state() -> void:
	var should_open = _overlap_count > 0
	if should_open != _is_open:
		_is_open = should_open
		if get_node_or_null("/root/SoundManager") != null:
			SoundManager.play_gate_toggle()

	if _gate_visual:
		_gate_visual.is_open = _is_open
		_gate_visual.queue_redraw()

	if _switch_visual:
		_switch_visual.is_active = _is_open
		_switch_visual.queue_redraw()

	if _block_collision:
		_block_collision.set_deferred("disabled", _is_open)
