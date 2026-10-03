extends Area2D

signal player_reached_exit(exit_point: Area2D, body: Node2D)
signal player_left_exit(exit_point: Area2D, body: Node2D)

@export var width: int = 50
@export var height: int = 50

var _occupants: Array[Node2D] = []
var _sprite: Sprite2D
var _default_texture: DrawableTexture2D
var _occupied_texture: DrawableTexture2D

func is_occupied() -> bool:
	return _occupants.size() > 0

func get_occupants() -> Array[Node2D]:
	return _occupants

func _ready() -> void:
	_sprite = $Sprite2D
	var cs2d = $CollisionShape2D

	# Default state — green
	_default_texture = DrawableTexture2D.new()
	_default_texture.setup(
		width, height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(0.0, 1.0, 0.2, 0.8)
	)

	# Occupied state — bright yellow
	_occupied_texture = DrawableTexture2D.new()
	_occupied_texture.setup(
		width, height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(1.0, 0.9, 0.0, 1.0)
	)

	_sprite.texture = _default_texture

	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body not in _occupants:
		_occupants.append(body)
		_sprite.texture = _occupied_texture
		player_reached_exit.emit(self, body)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_occupants.erase(body)
		if _occupants.is_empty():
			_sprite.texture = _default_texture
		player_left_exit.emit(self, body)
