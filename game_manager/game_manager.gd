extends Node

var current_world: int = 1
var current_level: int = 1

const PROTOTYPE_SCENE: String = "res://prototype/prototype.tscn"
const MAIN_MENU_SCENE: String = "res://screens/main_menu/main_menu.tscn"
const LEVEL_SELECT_SCENE: String = "res://screens/level_select/level_select.tscn"

# Progress state
var _completed_levels: Array[String] = []
var _unlocked_levels: Array[String] = ["1_1"]

func _ready() -> void:
	load_progress()

# Returns the path to the level JSON file
func get_level_path(world: int, level: int) -> String:
	return "res://levels_data/world_%d/level_%d_%d.json" % [world, world, level]

# Checks if a given level file exists
func has_level(world: int, level: int) -> bool:
	var path = get_level_path(world, level)
	return FileAccess.file_exists(path)

# Reads and returns the JSON string content for the current active level
func get_current_level_json_data() -> String:
	var path = get_level_path(current_world, current_level)
	if FileAccess.file_exists(path):
		return FileIO.readFile(path)
	
	# Fallback to default level.json if specific level is not found
	print("GameManager: Specific level not found at %s, falling back to default level.json" % path)
	return FileIO.readFile(FileNames.Level)

# Checks if there is a next level for the specified world and level
func get_next_level_for(world: int, level: int) -> Dictionary:
	# Try next level in current world
	if has_level(world, level + 1):
		return {"exists": true, "world": world, "level": level + 1}
	
	# Try level 1 in the next world
	if has_level(world + 1, 1):
		return {"exists": true, "world": world + 1, "level": 1}
	
	return {"exists": false, "world": world, "level": level}

# Checks if there is a next level for the active level
func get_next_level_info() -> Dictionary:
	return get_next_level_for(current_world, current_level)

# ── Progression & Save / Load (Android & Cross-Platform user://) ──────────────

func is_level_unlocked(world: int, level: int) -> bool:
	# World 1 Level 1 is always unlocked
	if world == 1 and level == 1:
		return true
	return _unlocked_levels.has("%d_%d" % [world, level])

func is_level_completed(world: int, level: int) -> bool:
	return _completed_levels.has("%d_%d" % [world, level])

func is_world_unlocked(world: int) -> bool:
	if world <= 1:
		return true
	# A world is unlocked if its first level is unlocked
	return is_level_unlocked(world, 1)

func complete_level(world: int, level: int) -> void:
	var key = "%d_%d" % [world, level]
	if not _completed_levels.has(key):
		_completed_levels.append(key)
		print("GameManager: Level completed: World %d, Level %d" % [world, level])

	# Unlock the next level (same world or next world)
	var next_info = get_next_level_for(world, level)
	if next_info.exists:
		var next_key = "%d_%d" % [next_info.world, next_info.level]
		if not _unlocked_levels.has(next_key):
			_unlocked_levels.append(next_key)
			print("GameManager: Unlocked new level: World %d, Level %d" % [next_info.world, next_info.level])

	save_progress()

func save_progress() -> bool:
	var save_dict: Dictionary = {
		"version": 1,
		"completed_levels": _completed_levels,
		"unlocked_levels": _unlocked_levels
	}
	var json_string = JSON.stringify(save_dict, "\t")
	var success = FileIO.writeFile(FileNames.SaveData, json_string)
	if success:
		print("GameManager: Game progress saved to %s" % FileNames.SaveData)
	else:
		push_error("GameManager: Failed to save progress to %s" % FileNames.SaveData)
	return success

func load_progress() -> void:
	_completed_levels = []
	_unlocked_levels = ["1_1"]

	if not FileAccess.file_exists(FileNames.SaveData):
		print("GameManager: No save file found at %s. Initialized fresh progress." % FileNames.SaveData)
		save_progress()
		return

	var content = FileIO.readFile(FileNames.SaveData)
	if content.is_empty():
		push_warning("GameManager: Save file empty. Using default progress.")
		return

	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		push_error("GameManager: Error parsing save file JSON: %s" % json.get_error_message())
		return

	var data = json.data
	if data is Dictionary:
		if data.has("completed_levels") and data["completed_levels"] is Array:
			for item in data["completed_levels"]:
				if item is String and not _completed_levels.has(item):
					_completed_levels.append(item)

		if data.has("unlocked_levels") and data["unlocked_levels"] is Array:
			for item in data["unlocked_levels"]:
				if item is String and not _unlocked_levels.has(item):
					_unlocked_levels.append(item)

	# Ensure World 1 Level 1 is always unlocked
	if not _unlocked_levels.has("1_1"):
		_unlocked_levels.append("1_1")

	# Self-healing: ensure any next levels of completed levels are unlocked
	for comp in _completed_levels:
		var parts = comp.split("_")
		if parts.size() == 2:
			var w = parts[0].to_int()
			var l = parts[1].to_int()
			var nxt = get_next_level_for(w, l)
			if nxt.exists:
				var nxt_key = "%d_%d" % [nxt.world, nxt.level]
				if not _unlocked_levels.has(nxt_key):
					_unlocked_levels.append(nxt_key)

	print("GameManager: Progress loaded. Completed: %s, Unlocked: %s" % [str(_completed_levels), str(_unlocked_levels)])

func reset_progress() -> void:
	_completed_levels.clear()
	_unlocked_levels = ["1_1"]
	save_progress()

# ── Scene Navigation & Level Loading ──────────────────────────────────────────

# Loads a specific world and level if unlocked
func load_level(world: int, level: int) -> void:
	if not is_level_unlocked(world, level):
		push_warning("GameManager: Cannot load locked level World %d, Level %d" % [world, level])
		return
	get_tree().paused = false
	current_world = world
	current_level = level
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)

# Restarts the currently active level
func restart_current_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)

# Loads the next level if one exists and is unlocked
func load_next_level() -> void:
	var next_info = get_next_level_info()
	if next_info.exists and is_level_unlocked(next_info.world, next_info.level):
		load_level(next_info.world, next_info.level)
	else:
		go_to_level_select()

# Navigates to the level select screen
func go_to_level_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

# Navigates to the main menu screen
func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

