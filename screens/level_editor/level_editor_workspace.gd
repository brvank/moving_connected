extends Control

signal item_selected(item_data: Dictionary)
signal item_deselected()

# Snapping grid size
const GRID_SIZE: int = 10

# Item visual sizes (width, height)
const ITEM_SIZES: Dictionary = {
	"player": Vector2(32, 32),
	"exit": Vector2(50, 50),
	"fixed_block": Vector2(20, 50),
	"shifting_block": Vector2(20, 50),
	"signal_gate_block": Vector2(20, 50),
	"signal_gate_switch": Vector2(20, 20),
	"fixed_danger": Vector2(20, 50),
	"shifting_danger": Vector2(20, 50),
	"timed_danger": Vector2(20, 50),
}

# Item colors matching game entities
const ITEM_COLORS: Dictionary = {
	"player": Color(0.2, 0.9, 1.0, 1.0),
	"exit": Color(0.0, 1.0, 0.65, 0.85),
	"fixed_block": Color(0.18, 0.28, 0.42, 1.0),
	"shifting_block": Color(1.0, 0.6, 0.15, 1.0),
	"signal_gate_block": Color(0.65, 0.15, 1.0, 1.0),
	"signal_gate_switch": Color(0.0, 0.85, 0.75, 0.85),
	"fixed_danger": Color(1.0, 0.08, 0.25, 0.8),
	"shifting_danger": Color(1.0, 0.08, 0.25, 0.8),
	"timed_danger": Color(1.0, 0.08, 0.25, 0.6),
}

# Display labels for items
const ITEM_LABELS: Dictionary = {
	"player": "P",
	"exit": "EXIT",
	"fixed_block": "FB",
	"shifting_block": "SB",
	"signal_gate_block": "GATE",
	"signal_gate_switch": "SW",
	"fixed_danger": "DANGER",
	"shifting_danger": "SD",
	"timed_danger": "TD",
}

# Placed items: Array of Dictionaries
# { "type": String, "position": Vector2, "node": Node2D, "direction": int, "linked_to": int }
var placed_items: Array[Dictionary] = []

var _selected_index: int = -1
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _boundary_size: Vector2 = Vector2(1000, 600)

@onready var items_container: Node2D = $ItemsContainer

func _ready() -> void:
	custom_minimum_size = _boundary_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func set_boundary(size: Vector2) -> void:
	_boundary_size = size
	custom_minimum_size = _boundary_size
	
	# Clamp any existing items within new boundary
	for item in placed_items:
		if item.type == "__removed__":
			continue
		item.position = _clamp_to_boundary(item.position, item.type, Vector2(item.width, item.height))
		if item.node and is_instance_valid(item.node):
			item.node.position = item.position
	
	queue_redraw()

func add_item(type: String, pos: Vector2, direction: int = 0, linked_to: int = -1, custom_width: int = -1, custom_height: int = -1) -> int:
	var def_size = ITEM_SIZES.get(type, Vector2(20, 20))
	var w = custom_width if custom_width > 0 else int(def_size.x)
	var h = custom_height if custom_height > 0 else int(def_size.y)
	var clamped_pos = _clamp_to_boundary(_snap_to_grid(pos), type, Vector2(w, h))
	var item_data: Dictionary = {
		"type": type,
		"position": clamped_pos,
		"direction": direction,
		"linked_to": linked_to,
		"width": w,
		"height": h,
		"node": null
	}
	placed_items.append(item_data)
	var idx = placed_items.size() - 1
	_create_item_visual(idx)
	_select_item(idx)
	queue_redraw()
	return idx

func remove_item(index: int) -> void:
	if index < 0 or index >= placed_items.size():
		return
	
	var item = placed_items[index]
	
	# If this is a signal gate block, also remove linked switch (and vice versa)
	if item.type == "signal_gate_block" and item.linked_to >= 0:
		var switch_idx = item.linked_to
		if switch_idx < placed_items.size():
			var switch_item = placed_items[switch_idx]
			if switch_item.node and is_instance_valid(switch_item.node):
				switch_item.node.queue_free()
			placed_items[switch_idx] = {"type": "__removed__", "position": Vector2.ZERO, "direction": 0, "linked_to": -1, "node": null}
	elif item.type == "signal_gate_switch" and item.linked_to >= 0:
		var block_idx = item.linked_to
		if block_idx < placed_items.size():
			var block_item = placed_items[block_idx]
			if block_item.node and is_instance_valid(block_item.node):
				block_item.node.queue_free()
			placed_items[block_idx] = {"type": "__removed__", "position": Vector2.ZERO, "direction": 0, "linked_to": -1, "node": null}
	
	if item.node and is_instance_valid(item.node):
		item.node.queue_free()
	placed_items[index] = {"type": "__removed__", "position": Vector2.ZERO, "direction": 0, "linked_to": -1, "node": null}
	
	if _selected_index == index or (item.linked_to >= 0 and _selected_index == item.linked_to):
		_selected_index = -1
		item_deselected.emit()
	
	queue_redraw()

func get_selected_item() -> Dictionary:
	if _selected_index >= 0 and _selected_index < placed_items.size():
		return placed_items[_selected_index]
	return {}

func get_selected_index() -> int:
	return _selected_index

func update_item_direction(index: int, direction: int) -> void:
	if index >= 0 and index < placed_items.size():
		placed_items[index].direction = direction
		_update_badge(index)
		queue_redraw()

func clear_all() -> void:
	for item in placed_items:
		if item.node and is_instance_valid(item.node):
			item.node.queue_free()
	placed_items.clear()
	_selected_index = -1
	item_deselected.emit()
	queue_redraw()

func _create_item_visual(index: int) -> void:
	var item = placed_items[index]
	var type = item.type
	var size = Vector2(item.width, item.height)
	var color = ITEM_COLORS.get(type, Color.WHITE)
	
	var container = Node2D.new()
	container.position = item.position
	
	# Visual sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	var texture = DrawableTexture2D.new()
	texture.setup(int(size.x), int(size.y), DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, color)
	sprite.texture = texture
	container.add_child(sprite)
	
	# Text label
	var label = Label.new()
	label.name = "Label"
	label.text = ITEM_LABELS.get(type, "?")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-size.x / 2.0, -size.y / 2.0)
	label.size = size
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color.BLACK if type in ["player", "exit"] else Color.WHITE)
	container.add_child(label)
	
	# Direction badge (for shifting types)
	var badge = Label.new()
	badge.name = "Badge"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = Vector2(-size.x / 2.0, size.y / 2.0)
	badge.size = Vector2(size.x, 14)
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color.YELLOW)
	if type in ["shifting_block", "shifting_danger"]:
		badge.text = "↕" if item.direction == 0 else "↔"
	container.add_child(badge)
	
	items_container.add_child(container)
	placed_items[index].node = container

func update_item_size(index: int, w: int, h: int) -> void:
	if index < 0 or index >= placed_items.size():
		return
	var item = placed_items[index]
	item.width = max(10, w)
	item.height = max(10, h)
	item.position = _clamp_to_boundary(item.position, item.type, Vector2(item.width, item.height))
	if item.node and is_instance_valid(item.node):
		item.node.position = item.position
		var sprite = item.node.get_node_or_null("Sprite") as Sprite2D
		if sprite:
			var texture = DrawableTexture2D.new()
			var color = ITEM_COLORS.get(item.type, Color.WHITE)
			texture.setup(item.width, item.height, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, color)
			sprite.texture = texture
		var label = item.node.get_node_or_null("Label") as Label
		if label:
			label.position = Vector2(-item.width / 2.0, -item.height / 2.0)
			label.size = Vector2(item.width, item.height)
		var badge = item.node.get_node_or_null("Badge") as Label
		if badge:
			badge.position = Vector2(-item.width / 2.0, item.height / 2.0)
			badge.size = Vector2(item.width, 14)
	queue_redraw()

func _update_badge(index: int) -> void:
	if index < 0 or index >= placed_items.size():
		return
	var item = placed_items[index]
	if item.node and is_instance_valid(item.node):
		var badge = item.node.get_node_or_null("Badge") as Label
		if badge and item.type in ["shifting_block", "shifting_danger"]:
			badge.text = "↕" if item.direction == 0 else "↔"

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		snapped(pos.x, GRID_SIZE),
		snapped(pos.y, GRID_SIZE)
	)

func _clamp_to_boundary(pos: Vector2, type: String, custom_size: Vector2 = Vector2.ZERO) -> Vector2:
	var size = custom_size if custom_size != Vector2.ZERO else (ITEM_SIZES.get(type, Vector2(20, 20)))
	var half = size / 2.0
	# Account for 20px walls
	var min_x = half.x + 20.0
	var min_y = half.y + 20.0
	var max_x = _boundary_size.x - half.x - 20.0
	var max_y = _boundary_size.y - half.y - 20.0
	
	if max_x < min_x:
		max_x = min_x
	if max_y < min_y:
		max_y = min_y
		
	return Vector2(
		clampf(pos.x, min_x, max_x),
		clampf(pos.y, min_y, max_y)
	)

func _find_item_at(pos: Vector2) -> int:
	for i in range(placed_items.size() - 1, -1, -1):
		var item = placed_items[i]
		if item.type == "__removed__":
			continue
		var size = Vector2(item.width, item.height) if item.has("width") and item.has("height") else ITEM_SIZES.get(item.type, Vector2(20, 20))
		var half = size / 2.0
		var rect = Rect2(item.position - half, size)
		# Slightly expand hit area for easy grabbing
		rect = rect.grow(6.0)
		if rect.has_point(pos):
			return i
	return -1

func _select_item(index: int) -> void:
	if _selected_index >= 0 and _selected_index < placed_items.size():
		var prev = placed_items[_selected_index]
		if prev.node and is_instance_valid(prev.node):
			prev.node.modulate = Color.WHITE
	
	_selected_index = index
	
	if index >= 0 and index < placed_items.size():
		var item = placed_items[index]
		if item.node and is_instance_valid(item.node):
			item.node.modulate = Color(1.5, 1.4, 0.4, 1.0)
		item_selected.emit(item)
	else:
		item_deselected.emit()
	
	queue_redraw()

func _deselect() -> void:
	if _selected_index >= 0 and _selected_index < placed_items.size():
		var prev = placed_items[_selected_index]
		if prev.node and is_instance_valid(prev.node):
			prev.node.modulate = Color.WHITE
	_selected_index = -1
	item_deselected.emit()
	queue_redraw()

# ── GUI Input Handling ────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var hit_index = _find_item_at(mouse_event.position)
				if hit_index >= 0:
					_select_item(hit_index)
					_dragging = true
					_drag_offset = placed_items[hit_index].position - mouse_event.position
				else:
					_deselect()
			else:
				_dragging = false
				
	elif event is InputEventMouseMotion and _dragging:
		var motion_event = event as InputEventMouseMotion
		if _selected_index >= 0 and _selected_index < placed_items.size():
			var item = placed_items[_selected_index]
			var new_pos = motion_event.position + _drag_offset
			new_pos = _snap_to_grid(new_pos)
			new_pos = _clamp_to_boundary(new_pos, item.type, Vector2(item.width, item.height))
			item.position = new_pos
			if item.node and is_instance_valid(item.node):
				item.node.position = new_pos
			item_selected.emit(item)
			queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			if _selected_index >= 0:
				remove_item(_selected_index)
				get_viewport().set_input_as_handled()
		elif _selected_index >= 0 and _selected_index < placed_items.size():
			var item = placed_items[_selected_index]
			var delta = Vector2.ZERO
			if event.keycode == KEY_LEFT:
				delta.x = -GRID_SIZE
			elif event.keycode == KEY_RIGHT:
				delta.x = GRID_SIZE
			elif event.keycode == KEY_UP:
				delta.y = -GRID_SIZE
			elif event.keycode == KEY_DOWN:
				delta.y = GRID_SIZE
			
			if delta != Vector2.ZERO:
				item.position = _clamp_to_boundary(item.position + delta, item.type, Vector2(item.width, item.height))
				if item.node and is_instance_valid(item.node):
					item.node.position = item.position
				item_selected.emit(item)
				queue_redraw()
				get_viewport().set_input_as_handled()

# ── Drag and Drop from Palette ────────────────────────────────────────────────

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("type")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("type"):
		var type = str(data["type"])
		if type == "signal_gate":
			# Place both block and switch
			var block_pos = at_position + Vector2(-30, 0)
			var switch_pos = at_position + Vector2(30, 0)
			var b_idx = add_item("signal_gate_block", block_pos, 0, -1, 20, 50)
			var s_idx = add_item("signal_gate_switch", switch_pos, 0, b_idx, 20, 20)
			placed_items[b_idx].linked_to = s_idx
		else:
			add_item(type, at_position)

# ── Canvas Drawing ────────────────────────────────────────────────────────────

func _draw() -> void:
	# 1. Level Canvas Background
	draw_rect(Rect2(Vector2.ZERO, _boundary_size), Color(0.02, 0.035, 0.07, 1.0), true)
	
	# 2. Grid lines (subtle)
	var grid_step = 50.0
	var col_grid = Color(0.0, 0.75, 1.0, 0.12)
	var x = 0.0
	while x <= _boundary_size.x:
		draw_line(Vector2(x, 0), Vector2(x, _boundary_size.y), col_grid, 1.0)
		x += grid_step
	var y = 0.0
	while y <= _boundary_size.y:
		draw_line(Vector2(0, y), Vector2(_boundary_size.x, y), col_grid, 1.0)
		y += grid_step
		
	# 3. Outer boundary walls (thickness 20px, matching game launcher walls)
	var wall_color = Color(0.05, 0.08, 0.16, 1.0) # sci-fi hull color
	var wall_thickness = 20.0
	# Top wall
	draw_rect(Rect2(0, 0, _boundary_size.x, wall_thickness), wall_color, true)
	# Bottom wall
	draw_rect(Rect2(0, _boundary_size.y - wall_thickness, _boundary_size.x, wall_thickness), wall_color, true)
	# Left wall
	draw_rect(Rect2(0, 0, wall_thickness, _boundary_size.y), wall_color, true)
	# Right wall
	draw_rect(Rect2(_boundary_size.x - wall_thickness, 0, wall_thickness, _boundary_size.y), wall_color, true)
	# Glowing containment perimeter inner stroke
	draw_rect(Rect2(wall_thickness, wall_thickness, _boundary_size.x - 2.0 * wall_thickness, _boundary_size.y - 2.0 * wall_thickness), Color(0.0, 0.9, 1.0, 0.85), false, 2.0)
	
	# 4. Connecting lines for Signal Gates
	for item in placed_items:
		if item.type == "signal_gate_block" and item.linked_to >= 0 and item.linked_to < placed_items.size():
			var switch_item = placed_items[item.linked_to]
			if switch_item.type == "signal_gate_switch":
				draw_dashed_line(item.position, switch_item.position, Color(0.6, 0.2, 1.0, 0.8), 2.0, 6.0)
				
	# 5. Selected item highlight box
	if _selected_index >= 0 and _selected_index < placed_items.size():
		var sel = placed_items[_selected_index]
		if sel.type != "__removed__":
			var size = Vector2(sel.width, sel.height) if sel.has("width") and sel.has("height") else ITEM_SIZES.get(sel.type, Vector2(20, 20))
			var half = size / 2.0
			var sel_rect = Rect2(sel.position - half, size).grow(4.0)
			draw_rect(sel_rect, Color(1.0, 0.9, 0.2, 0.9), false, 2.0)

# ── JSON Export ───────────────────────────────────────────────────────────────

func generate_json() -> String:
	var players: Array = []
	var exits: Array = []
	var fixed_blocks: Array = []
	var shifting_blocks: Array = []
	var signal_gates: Array = []
	var fixed_dangers: Array = []
	var shifting_dangers: Array = []
	var timed_dangers: Array = []
	
	for i in placed_items.size():
		var item = placed_items[i]
		if item.type == "__removed__":
			continue
		
		var pos = item.position
		var w: int = int(item.get("width", 20))
		var h: int = int(item.get("height", 50))
		match item.type:
			"player":
				players.append([int(pos.x), int(pos.y)])
			"exit":
				exits.append([int(pos.x), int(pos.y)])
			"fixed_block":
				fixed_blocks.append([int(pos.x), int(pos.y), w, h])
			"shifting_block":
				shifting_blocks.append([int(pos.x), int(pos.y), item.direction, w, h])
			"signal_gate_block":
				if item.linked_to >= 0 and item.linked_to < placed_items.size():
					var switch_item = placed_items[item.linked_to]
					if switch_item.type == "signal_gate_switch":
						var sw_w: int = int(switch_item.get("width", 20))
						var sw_h: int = int(switch_item.get("height", 20))
						signal_gates.append([
							int(pos.x), int(pos.y),
							int(switch_item.position.x), int(switch_item.position.y),
							w, h,
							sw_w, sw_h
						])
			"fixed_danger":
				fixed_dangers.append([int(pos.x), int(pos.y), w, h])
			"shifting_danger":
				shifting_dangers.append([int(pos.x), int(pos.y), item.direction, w, h])
			"timed_danger":
				timed_dangers.append([int(pos.x), int(pos.y), w, h])
	
	var level_dict: Dictionary = {
		"w": [[0, 0], [int(_boundary_size.x), int(_boundary_size.y)]],
		"p": players,
		"e": exits,
		"o": {
			"fb": fixed_blocks,
			"sb": shifting_blocks,
			"sg": signal_gates,
			"fd": fixed_dangers,
			"sd": shifting_dangers,
			"td": timed_dangers
		}
	}
	
	return JSON.stringify(level_dict, "\t")
