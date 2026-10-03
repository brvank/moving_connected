extends StaticBody2D

@export var width = 20
@export var height = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var sprite2d = $Sprite2D
	var cs2d = $CollisionShape2D
	
	var texture2d = DrawableTexture2D.new()
	texture2d.setup(
		width, 
		height, 
		DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, 
		Color(1.0, 0.502, 0.051, 1.0)
	)
	sprite2d.texture = texture2d
	var rShape2d = RectangleShape2D.new()
	rShape2d.size = Vector2(width, height)
	cs2d.shape = rShape2d
