extends Line2D

# Set dynamically by the game launcher
var tracked_nodes: Array[Node2D] = []

func set_tracked_nodes(nodes: Array[Node2D]) -> void:
	tracked_nodes = nodes
	clear_points()
	for i in range(nodes.size()):
		add_point(Vector2.ZERO)

func _process(_delta: float) -> void:
	for i in range(tracked_nodes.size()):
		if is_instance_valid(tracked_nodes[i]):
			set_point_position(i, to_local(tracked_nodes[i].global_position))
