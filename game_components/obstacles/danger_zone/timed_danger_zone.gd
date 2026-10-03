extends Area2D

signal player_hit_danger(danger_zone: Area2D, body: Node2D)

@export var width: int = 20
@export var height: int = 50
@export var active_duration: float = 2.0
@export var inactive_duration: float = 2.0

var _is_active: bool = true
var _active_texture: DrawableTexture2D
var _inactive_texture: DrawableTexture2D
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = $Sprite2D
	var cs2d = $CollisionShape2D

	# Active state — solid red
	_active_texture = DrawableTexture2D.new()
	_active_texture.setup(
		width, height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(1.0, 0.0, 0.0, 0.7)
	)

	# Inactive state — faded red
	_inactive_texture = DrawableTexture2D.new()
	_inactive_texture.setup(
		width, height,
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8,
		Color(1.0, 0.0, 0.0, 0.15)
	)

	_sprite.texture = _active_texture

	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d

	body_entered.connect(_on_body_entered)
	_start_timer_cycle()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and _is_active:
		player_hit_danger.emit(self, body)

func _start_timer_cycle() -> void:
	while is_inside_tree():
		# Active phase — dangerous
		_is_active = true
		monitoring = true
		_sprite.texture = _active_texture
		await get_tree().create_timer(active_duration).timeout
		if not is_inside_tree():
			break
		# Inactive phase — safe to pass
		_is_active = false
		monitoring = false
		_sprite.texture = _inactive_texture
		await get_tree().create_timer(inactive_duration).timeout
