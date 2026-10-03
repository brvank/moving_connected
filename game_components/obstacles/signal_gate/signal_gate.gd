extends Node2D

@export var block_width: int = 20
@export var block_height: int = 50
@export var switch_width: int = 20
@export var switch_height: int = 20

var block_position: Vector2
var switch_position: Vector2

var _overlap_count: int = 0
var _block_collision: CollisionShape2D
var _block_sprite: Sprite2D
var _switch_sprite: Sprite2D
var _closed_texture: DrawableTexture2D
var _open_texture: DrawableTexture2D

func _ready() -> void:
	# ── Gate block (StaticBody2D at block_position) ───────────────────────────
	var block = StaticBody2D.new()
	block.position = block_position

	_block_sprite = Sprite2D.new()
	_closed_texture = DrawableTexture2D.new()
	_closed_texture.setup(
		block_width, block_height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(0.5, 0.0, 1.0, 1.0)
	)
	_open_texture = DrawableTexture2D.new()
	_open_texture.setup(
		block_width, block_height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(0.5, 0.0, 1.0, 0.25)
	)
	_block_sprite.texture = _closed_texture
	block.add_child(_block_sprite)

	_block_collision = CollisionShape2D.new()
	var blockShape = RectangleShape2D.new()
	blockShape.size = Vector2(block_width, block_height)
	_block_collision.shape = blockShape
	block.add_child(_block_collision)

	add_child(block)

	# ── Switch (Area2D at switch_position) ────────────────────────────────────
	var switch_area = Area2D.new()
	switch_area.position = switch_position

	_switch_sprite = Sprite2D.new()
	var switchTexture = DrawableTexture2D.new()
	switchTexture.setup(
		switch_width, switch_height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(0.0, 0.8, 0.4, 0.8)
	)
	_switch_sprite.texture = switchTexture
	switch_area.add_child(_switch_sprite)

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
	if _overlap_count > 0:
		# Player on switch → gate open (collision disabled)
		_block_collision.set_deferred("disabled", true)
		_block_sprite.texture = _open_texture
	else:
		# No player on switch → gate closed (collision active)
		_block_collision.set_deferred("disabled", false)
		_block_sprite.texture = _closed_texture
