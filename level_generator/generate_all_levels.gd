extends SceneTree

func _init() -> void:
	print("==================================================")
	print("Starting Level Generation for All 4 Worlds...")
	print("==================================================")

	var gen := LevelGenerator.new()

	var worlds_config = [
		{
			"world": 1,
			"name": "World 1 - Kinetic Barriers",
			"obs_desc": "Fixed Blocks, Shifting Blocks",
			"obs": ["sb"]
		},
		{
			"world": 2,
			"name": "World 2 - Radiation Fields",
			"obs_desc": "Fixed Blocks, Shifting Blocks, Danger Zones, Shifting Danger Zones",
			"obs": ["sb", "fd", "sd"]
		},
		{
			"world": 3,
			"name": "World 3 - Pulsing Flux",
			"obs_desc": "Fixed Blocks, Shifting Blocks, Danger Zones, Shifting Danger Zones, Timed Danger Zones",
			"obs": ["sb", "fd", "sd", "td"]
		},
		{
			"world": 4,
			"name": "World 4 - Quantum Phase Gates",
			"obs_desc": "Fixed Blocks, Shifting Blocks, Danger Zones, Shifting Danger Zones, Timed Danger Zones, Signal Gates",
			"obs": ["sb", "fd", "sd", "td", "sg"]
		}
	]

	var difficulties_distribution = [
		"easy", "easy", "easy",
		"medium", "medium", "medium",
		"hard", "hard", "hard",
		"expert", "expert", "expert"
	]

	var all_answers_text: String = ""
	all_answers_text += "================================================================================\n"
	all_answers_text += "                       MOVING CONNECTED - LEVEL ANSWERS\n"
	all_answers_text += "================================================================================\n"
	all_answers_text += "Total Worlds: 4\n"
	all_answers_text += "Levels per World: 12 (3 Easy, 3 Medium, 3 Hard, 3 Expert)\n"
	all_answers_text += "Total Levels: 48\n\n"
	all_answers_text += "Obstacle Types:\n"
	all_answers_text += "  fb: Fixed Blocks (Walls)\n"
	all_answers_text += "  sb: Shifting Blocks\n"
	all_answers_text += "  fd: Danger Zones (Fixed)\n"
	all_answers_text += "  sd: Shifting Danger Zones\n"
	all_answers_text += "  td: Timed Danger Zones\n"
	all_answers_text += "  sg: Signal Gates & Terminals\n\n"
	all_answers_text += "Move Directions:\n"
	all_answers_text += "  U: Up | D: Down | L: Left | R: Right\n"
	all_answers_text += "================================================================================\n\n"

	var total_start_time = Time.get_ticks_msec()

	for w_info in worlds_config:
		var w_num: int = w_info["world"]
		var w_name: String = w_info["name"]
		var obs_list: Array = w_info["obs"]
		var obs_desc: String = w_info["obs_desc"]

		print("\n--------------------------------------------------")
		print("Generating %s..." % w_name)
		print("Obstacles: %s" % obs_desc)
		print("--------------------------------------------------")

		all_answers_text += "--------------------------------------------------------------------------------\n"
		all_answers_text += "%s\n" % w_name.to_upper()
		all_answers_text += "Obstacles: %s\n" % obs_desc
		all_answers_text += "--------------------------------------------------------------------------------\n\n"

		for lvl_idx in range(difficulties_distribution.size()):
			var lvl_num: int = lvl_idx + 1
			var diff: String = difficulties_distribution[lvl_idx]
			var file_rel_path: String = "levels_data/world_%d/level_%d_%d.json" % [w_num, w_num, lvl_num]
			var file_res_path: String = "res://" + file_rel_path

			var t0 = Time.get_ticks_msec()
			var res: Dictionary = {}
			var attempts_count: int = 0
			while res.is_empty():
				attempts_count += 1
				res = gen.generate_level(diff, obs_list)

			var dt = Time.get_ticks_msec() - t0
			var level_data: Dictionary = res["level"]
			var meta: Dictionary = res["meta"]
			var par_moves: int = meta["par_moves"]
			var stalls: int = meta["wall_stalls"]
			var grid_size: Array = meta["grid_size"]
			var solution_arr: Array = meta["solution"]
			var solution_str: String = "".join(solution_arr)

			# Save level JSON file
			var json_content: String = JSON.stringify(level_data, "\t")
			var f = FileAccess.open(file_res_path, FileAccess.WRITE)
			if f:
				f.store_string(json_content)
				f.close()
			else:
				push_error("Failed to write to " + file_res_path)

			# Also write to android asset pack if directory exists
			var android_rel_path: String = "res://android/build/assetPackInstallTime/src/main/assets/" + file_rel_path
			if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://android/build/assetPackInstallTime/src/main/assets/levels_data/world_%d" % w_num)):
				var f_android = FileAccess.open(android_rel_path, FileAccess.WRITE)
				if f_android:
					f_android.store_string(json_content)
					f_android.close()

			print("  Level %d_%d [%s] generated in %d ms (%d attempts) -> Par: %d moves, Stalls: %d, Solution: %s" % [
				w_num, lvl_num, diff.capitalize(), dt, attempts_count, par_moves, stalls, solution_str
			])

			# Append to answers text
			all_answers_text += "World %d - Level %d [%s]\n" % [w_num, lvl_num, diff.capitalize()]
			all_answers_text += "  File: %s\n" % file_rel_path
			all_answers_text += "  Grid: %dx%d\n" % [grid_size[0], grid_size[1]]
			all_answers_text += "  Par Moves: %d | Wall Stalls: %d\n" % [par_moves, stalls]
			all_answers_text += "  Solution: %s\n" % solution_str
			all_answers_text += "  Steps: %s\n\n" % " -> ".join(solution_arr)

		all_answers_text += "\n"

	# Save answers.txt
	var ans_file = FileAccess.open("res://answers.txt", FileAccess.WRITE)
	if ans_file:
		ans_file.store_string(all_answers_text)
		ans_file.close()
		print("\nSuccessfully saved answers.txt to res://answers.txt")
	else:
		push_error("Failed to write answers.txt")


	var total_time = (Time.get_ticks_msec() - total_start_time) / 1000.0
	print("\nAll 48 levels generated successfully in %.2f seconds!" % total_time)
	quit()
