extends Line2D

# Assign the nodes you want to connect in the Inspector
@export var node_a: Node2D
@export var node_b: Node2D

func _ready() -> void:
	# Ensure the line has exactly two tracking points
	clear_points()
	add_point(Vector2.ZERO)
	add_point(Vector2.ZERO)

func _process(_delta: float) -> void:
	if is_instance_valid(node_a) and is_instance_valid(node_b):
		# Convert global positions to the Line2D's local coordinate space
		var pos_a = to_local(node_a.global_position)
		var pos_b = to_local(node_b.global_position)
		
		# Update the line segment positions
		set_point_position(0, pos_a)
		set_point_position(1, pos_b)
