extends Node

var current_world: int = 1
var current_level: int = 1

const PROTOTYPE_SCENE: String = "res://prototype/prototype.tscn"
const MAIN_MENU_SCENE: String = "res://screens/main_menu/main_menu.tscn"
const LEVEL_SELECT_SCENE: String = "res://screens/level_select/level_select.tscn"

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

# Checks if there is a next level (either in the same world or the next world)
func get_next_level_info() -> Dictionary:
	# Try next level in current world
	if has_level(current_world, current_level + 1):
		return {"exists": true, "world": current_world, "level": current_level + 1}
	
	# Try level 1 in the next world
	if has_level(current_world + 1, 1):
		return {"exists": true, "world": current_world + 1, "level": 1}
	
	return {"exists": false, "world": current_world, "level": current_level}

# Loads a specific world and level
func load_level(world: int, level: int) -> void:
	get_tree().paused = false
	current_world = world
	current_level = level
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)

# Restarts the currently active level
func restart_current_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)

# Loads the next level if one exists
func load_next_level() -> void:
	var next_info = get_next_level_info()
	if next_info.exists:
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

