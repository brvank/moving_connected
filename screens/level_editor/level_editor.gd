extends Control

@onready var boundary_width_spin: SpinBox = %BoundaryWidthSpin
@onready var boundary_height_spin: SpinBox = %BoundaryHeightSpin
@onready var selected_info_label: Label = %SelectedInfoLabel
@onready var direction_container: HBoxContainer = %DirectionContainer
@onready var direction_option: OptionButton = %DirectionOption
@onready var size_container: HBoxContainer = %SizeContainer
@onready var item_width_spin: SpinBox = %ItemWidthSpin
@onready var item_height_spin: SpinBox = %ItemHeightSpin
@onready var delete_selected_btn: Button = %DeleteSelectedBtn
@onready var workspace: Control = %Workspace

# Action and palette buttons
@onready var apply_boundary_btn: Button = %ApplyBoundaryBtn
@onready var add_player_btn: Button = %AddPlayerBtn
@onready var add_exit_btn: Button = %AddExitBtn
@onready var add_fixed_block_btn: Button = %AddFixedBlockBtn
@onready var add_shifting_block_btn: Button = %AddShiftingBlockBtn
@onready var add_signal_gate_btn: Button = %AddSignalGateBtn
@onready var add_fixed_danger_btn: Button = %AddFixedDangerBtn
@onready var add_shifting_danger_btn: Button = %AddShiftingDangerBtn
@onready var add_timed_danger_btn: Button = %AddTimedDangerBtn
@onready var load_json_btn: Button = %LoadJsonBtn
@onready var extract_json_btn: Button = %ExtractJsonBtn
@onready var play_test_btn: Button = %PlayTestBtn
@onready var clear_all_btn: Button = %ClearAllBtn
@onready var back_btn: Button = %BackBtn

var _json_dialog: AcceptDialog = null
var _load_json_dialog: ConfirmationDialog = null
var _file_dialog: FileDialog = null
var _alert_dialog: AcceptDialog = null

func _ready() -> void:
	# Configure direction dropdown
	direction_option.clear()
	direction_option.add_item("Vertical (0)", 0)
	direction_option.add_item("Horizontal (1)", 1)
	
	# Connect boundary controls
	apply_boundary_btn.pressed.connect(_on_apply_boundary)
	boundary_width_spin.value_changed.connect(func(_val): _on_apply_boundary())
	boundary_height_spin.value_changed.connect(func(_val): _on_apply_boundary())
	
	# Setup draggable palette buttons
	_setup_palette_button(add_player_btn, "player")
	_setup_palette_button(add_exit_btn, "exit")
	_setup_palette_button(add_fixed_block_btn, "fixed_block")
	_setup_palette_button(add_shifting_block_btn, "shifting_block")
	_setup_palette_button(add_signal_gate_btn, "signal_gate")
	_setup_palette_button(add_fixed_danger_btn, "fixed_danger")
	_setup_palette_button(add_shifting_danger_btn, "shifting_danger")
	_setup_palette_button(add_timed_danger_btn, "timed_danger")
	
	# Connect selection controls
	delete_selected_btn.pressed.connect(_on_delete_selected)
	direction_option.item_selected.connect(_on_direction_changed)
	item_width_spin.value_changed.connect(_on_item_size_changed)
	item_height_spin.value_changed.connect(_on_item_size_changed)
	
	# Connect action buttons
	load_json_btn.pressed.connect(_on_load_json)
	extract_json_btn.pressed.connect(_on_extract_json)
	play_test_btn.pressed.connect(_on_play_test)
	clear_all_btn.pressed.connect(_on_clear_all)
	back_btn.pressed.connect(_on_back)
	
	# Connect workspace signals
	workspace.item_selected.connect(_on_item_selected)
	workspace.item_deselected.connect(_on_item_deselected)
	
	# Initial boundary setup
	_on_apply_boundary()
	_on_item_deselected()
	
	# If returning from a test, restore previous custom JSON if any
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_testing_custom_level and not gm.custom_level_json.is_empty():
		_load_from_json(gm.custom_level_json)

func _setup_palette_button(btn: Button, item_type: String) -> void:
	# Click to place at center
	btn.pressed.connect(func():
		if item_type == "signal_gate":
			_on_add_signal_gate()
		else:
			_add_item(item_type)
	)
	
	# Enable drag and drop from palette onto workspace
	btn.set_drag_forwarding(
		func(_at_position: Vector2) -> Variant:
			var preview = Label.new()
			preview.text = btn.text
			preview.add_theme_font_size_override("font_size", 14)
			preview.modulate = Color(1.0, 1.0, 0.4, 1.0)
			btn.set_drag_preview(preview)
			return {"type": item_type},
		func(_at_pos: Vector2, _data: Variant) -> bool: return false,
		func(_at_pos: Vector2, _data: Variant) -> void: pass
	)

func _on_apply_boundary() -> void:
	var w = boundary_width_spin.value
	var h = boundary_height_spin.value
	workspace.set_boundary(Vector2(w, h))

func _add_item(type: String) -> void:
	var center = workspace._boundary_size / 2.0
	# Add slight random jitter so items don't stack directly on top of each other
	var jitter = Vector2(randf_range(-30, 30), randf_range(-30, 30))
	workspace.add_item(type, center + jitter)

func _on_add_signal_gate() -> void:
	var center = workspace._boundary_size / 2.0
	var block_idx = workspace.add_item("signal_gate_block", center + Vector2(-50, 0))
	var switch_idx = workspace.add_item("signal_gate_switch", center + Vector2(50, 0), 0, block_idx)
	workspace.placed_items[block_idx].linked_to = switch_idx
	workspace.queue_redraw()

func _on_delete_selected() -> void:
	var idx = workspace.get_selected_index()
	if idx >= 0:
		workspace.remove_item(idx)

func _on_direction_changed(dir_index: int) -> void:
	var idx = workspace.get_selected_index()
	if idx >= 0:
		workspace.update_item_direction(idx, dir_index)

func _on_item_size_changed(_val: float = 0.0) -> void:
	var idx = workspace.get_selected_index()
	if idx >= 0:
		var w = int(item_width_spin.value)
		var h = int(item_height_spin.value)
		workspace.update_item_size(idx, w, h)
		var item = workspace.get_selected_item()
		if not item.is_empty():
			var type_name = item.type.replace("_", " ").capitalize()
			var info = "%s\nPosition: (%d, %d)\nSize: %d x %d" % [type_name, int(item.position.x), int(item.position.y), int(item.width), int(item.height)]
			if item.type in ["shifting_block", "shifting_danger"]:
				info += "\nDirection: %s" % ["Vertical" if item.direction == 0 else "Horizontal"]
			selected_info_label.text = info

func _on_item_selected(item_data: Dictionary) -> void:
	var type_name = item_data.type.replace("_", " ").capitalize()
	var info = "%s\nPosition: (%d, %d)" % [type_name, int(item_data.position.x), int(item_data.position.y)]
	if item_data.has("width") and item_data.has("height"):
		info += "\nSize: %d x %d" % [int(item_data.width), int(item_data.height)]
	if item_data.has("direction") and item_data.type in ["shifting_block", "shifting_danger"]:
		info += "\nDirection: %s" % ["Vertical" if item_data.direction == 0 else "Horizontal"]
	selected_info_label.text = info
	delete_selected_btn.visible = true
	
	var has_direction = item_data.type in ["shifting_block", "shifting_danger"]
	direction_container.visible = has_direction
	if has_direction:
		direction_option.selected = item_data.direction

	var is_resizable = item_data.type in ["fixed_block", "shifting_block", "signal_gate_block", "signal_gate_switch", "fixed_danger", "shifting_danger", "timed_danger"]
	size_container.visible = is_resizable
	if is_resizable and item_data.has("width") and item_data.has("height"):
		item_width_spin.set_value_no_signal(item_data.width)
		item_height_spin.set_value_no_signal(item_data.height)

func _on_item_deselected() -> void:
	selected_info_label.text = "Click or drag an item to place it.\nClick placed item to select/move."
	delete_selected_btn.visible = false
	direction_container.visible = false
	size_container.visible = false

# ── Feature: Load Level JSON Data ─────────────────────────────────────────────

func _on_load_json() -> void:
	if _load_json_dialog:
		_load_json_dialog.queue_free()
	
	_load_json_dialog = ConfirmationDialog.new()
	_load_json_dialog.title = "Load Level JSON Data"
	_load_json_dialog.size = Vector2i(580, 360)
	_load_json_dialog.ok_button_text = "Load into Editor"
	_load_json_dialog.cancel_button_text = "Cancel"
	
	_load_json_dialog.add_button("Load & Play Test", false, "play_test")
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	
	var notice_label = Label.new()
	notice_label.text = "Paste or load JSON data below to import into editor or test:"
	notice_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 1.0))
	vbox.add_child(notice_label)
	
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	
	var paste_btn = Button.new()
	paste_btn.text = "📋 Paste from Clipboard"
	btn_row.add_child(paste_btn)
	
	var browse_btn = Button.new()
	browse_btn.text = "📁 Browse File..."
	btn_row.add_child(browse_btn)
	
	var sample_btn = Button.new()
	sample_btn.text = "📄 Sample Level"
	btn_row.add_child(sample_btn)
	
	vbox.add_child(btn_row)
	
	var text_edit = TextEdit.new()
	text_edit.placeholder_text = "{\n\t\"w\": [[0,0],[1000,600]],\n\t\"p\": [[200,250],[200,450]],\n\t\"e\": [[850,200],[850,450]],\n\t\"o\": {\n\t\t\"fb\": [[400,250,20,50]],\n\t\t\"sb\": [[500,320,0,20,50]],\n\t\t\"sg\": [],\n\t\t\"fd\": [],\n\t\t\"sd\": [],\n\t\t\"td\": []\n\t}\n}"
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size = Vector2(0, 180)
	text_edit.editable = true
	vbox.add_child(text_edit)
	
	# Auto-fill from clipboard if it contains JSON
	var clipboard_text = DisplayServer.clipboard_get().strip_edges()
	if clipboard_text.begins_with("{") and clipboard_text.ends_with("}"):
		text_edit.text = clipboard_text
	
	paste_btn.pressed.connect(func():
		var clip = DisplayServer.clipboard_get()
		if not clip.is_empty():
			text_edit.text = clip
	)
	
	browse_btn.pressed.connect(func():
		_open_file_dialog(text_edit)
	)
	
	sample_btn.pressed.connect(func():
		var default_data = FileIO.readFile(FileNames.Level)
		if not default_data.is_empty():
			text_edit.text = default_data
	)
	
	_load_json_dialog.confirmed.connect(func():
		var raw = text_edit.text.strip_edges()
		_execute_load_json(raw, false)
	)
	
	_load_json_dialog.custom_action.connect(func(action: StringName):
		if action == "play_test":
			var raw = text_edit.text.strip_edges()
			_execute_load_json(raw, true)
	)
	
	_load_json_dialog.add_child(vbox)
	add_child(_load_json_dialog)
	_load_json_dialog.popup_centered()

func _open_file_dialog(target_text_edit: TextEdit) -> void:
	if _file_dialog:
		_file_dialog.queue_free()
	
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.json ; JSON Files"])
	_file_dialog.title = "Select Level JSON File"
	_file_dialog.size = Vector2i(580, 360)
	
	var levels_path = ProjectSettings.globalize_path("res://levels_data")
	_file_dialog.current_dir = levels_path
	
	_file_dialog.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			target_text_edit.text = content
		else:
			_show_alert("Failed to open file: " + path)
	)
	
	add_child(_file_dialog)
	_file_dialog.popup_centered()

func _execute_load_json(raw: String, auto_play: bool) -> void:
	if raw.is_empty():
		_show_alert("JSON data is empty! Please enter or paste level JSON.")
		return
	
	var parsed_data = LevelDataParser.parseLevelData(raw)
	if parsed_data == null:
		_show_alert("Failed to parse level JSON data.\nPlease ensure the JSON is in valid format.")
		return
	
	_load_from_json(raw)
	
	if _load_json_dialog and is_instance_valid(_load_json_dialog):
		_load_json_dialog.hide()
	
	if auto_play:
		_on_play_test()

# ── Feature 1: Extract Level JSON Data ────────────────────────────────────────

func _on_extract_json() -> void:
	var json_str = workspace.generate_json()
	DisplayServer.clipboard_set(json_str)
	
	if _json_dialog:
		_json_dialog.queue_free()
	
	_json_dialog = AcceptDialog.new()
	_json_dialog.title = "Level JSON Data (Copied to Clipboard!)"
	_json_dialog.size = Vector2i(560, 360)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	
	var notice_label = Label.new()
	notice_label.text = "JSON copied to clipboard! You can also copy it manually below:"
	notice_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6, 1.0))
	vbox.add_child(notice_label)
	
	var text_edit = TextEdit.new()
	text_edit.text = json_str
	text_edit.size_flags_vertical = SIZE_EXPAND_FILL
	text_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	text_edit.custom_minimum_size = Vector2(0, 200)
	text_edit.editable = false
	vbox.add_child(text_edit)
	
	_json_dialog.add_child(vbox)
	add_child(_json_dialog)
	_json_dialog.popup_centered()
	print("Level JSON extracted:\n", json_str)

# ── Feature 2: Play and Test Level ────────────────────────────────────────────

func _on_play_test() -> void:
	var json_str = workspace.generate_json()
	var test_data = LevelDataParser.parseLevelData(json_str)
	
	if test_data == null:
		_show_alert("Failed to parse level JSON data.")
		return
	
	if test_data.playersLocations.size() < 2:
		_show_alert("Game requires at least 2 players connected by the line!\nPlease add another player.")
		return
		
	if test_data.exitsLocations.size() < 1:
		_show_alert("Game requires at least 1 exit point!\nPlease add an exit point.")
		return
	
	if test_data.playersLocations.size() < test_data.exitsLocations.size():
		_show_alert("Not enough players for all exit points!\nPlayers: %d, Exits: %d." % [test_data.playersLocations.size(), test_data.exitsLocations.size()])
		return
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.test_custom_level(json_str)
	else:
		_show_alert("GameManager autoload not found.")

func _show_alert(message: String) -> void:
	if _alert_dialog:
		_alert_dialog.queue_free()
	_alert_dialog = AcceptDialog.new()
	_alert_dialog.title = "Level Validation"
	_alert_dialog.dialog_text = message
	add_child(_alert_dialog)
	_alert_dialog.popup_centered()

func _on_clear_all() -> void:
	workspace.clear_all()
	_on_item_deselected()

func _on_back() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.is_testing_custom_level = false
		gm.go_to_main_menu()

func _load_from_json(json_str: String) -> void:
	var level_data = LevelDataParser.parseLevelData(json_str)
	if level_data == null:
		return
	
	workspace.clear_all()
	
	if level_data.windowSize:
		var w = level_data.windowSize.right
		var h = level_data.windowSize.bottom
		boundary_width_spin.value = w
		boundary_height_spin.value = h
		workspace.set_boundary(Vector2(w, h))
	
	for p in level_data.playersLocations:
		workspace.add_item("player", p.position())
	for e in level_data.exitsLocations:
		workspace.add_item("exit", e.position())
	for fb in level_data.fixedBlocksLocations:
		workspace.add_item("fixed_block", fb.position(), 0, -1, fb.width, fb.height)
	for sb in level_data.shiftingBlocksLocations:
		workspace.add_item("shifting_block", sb.position(), sb.shiftingDirection, -1, sb.width, sb.height)
	for sg in level_data.signalGatesLocations:
		var b_idx = workspace.add_item("signal_gate_block", sg.block_position, 0, -1, sg.block_width, sg.block_height)
		var s_idx = workspace.add_item("signal_gate_switch", sg.switch_position, 0, b_idx, sg.switch_width, sg.switch_height)
		workspace.placed_items[b_idx].linked_to = s_idx
	for fd in level_data.fixedDangerZonesLocations:
		workspace.add_item("fixed_danger", fd.position(), 0, -1, fd.width, fd.height)
	for sd in level_data.shiftingDangerZonesLocations:
		workspace.add_item("shifting_danger", sd.position(), sd.shiftingDirection, -1, sd.width, sd.height)
	for td in level_data.timedDangerZonesLocations:
		workspace.add_item("timed_danger", td.position(), 0, -1, td.width, td.height)
	
	workspace._deselect()
	workspace.queue_redraw()
