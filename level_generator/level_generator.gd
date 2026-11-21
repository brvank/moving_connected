class_name LevelGenerator
extends RefCounted

const TILE: float = 50.0
const MARGIN: float = 20.0

const DIRS: Dictionary = {
	"U": Vector2i(-1, 0),
	"D": Vector2i(1, 0),
	"L": Vector2i(0, -1),
	"R": Vector2i(0, 1),
}

const OBSTACLE_KEYS: Array[String] = ["sb", "sg", "fd", "sd", "td"]

const DIFFICULTIES: Dictionary = {
	"easy": {
		"cols": Vector2i(6, 8), "rows": Vector2i(6, 8),
		"wall_ratio": 0.22,
		"moves": Vector2i(5, 10), "min_stalls": 1,
		"obs": {"fd": 1, "sg": 1, "sb": 1, "sd": 1, "td": 1},
	},
	"medium": {
		"cols": Vector2i(8, 10), "rows": Vector2i(8, 10),
		"wall_ratio": 0.25,
		"moves": Vector2i(11, 18), "min_stalls": 3,
		"obs": {"fd": 2, "sg": 1, "sb": 1, "sd": 1, "td": 1},
	},
	"hard": {
		"cols": Vector2i(11, 13), "rows": Vector2i(10, 13),
		"wall_ratio": 0.27,
		"moves": Vector2i(19, 28), "min_stalls": 5,
		"obs": {"fd": 3, "sg": 1, "sb": 2, "sd": 1, "td": 2},
	},
	"expert": {
		"cols": Vector2i(14, 16), "rows": Vector2i(13, 16),
		"wall_ratio": 0.29,
		"moves": Vector2i(29, 45), "min_stalls": 7,
		"obs": {"fd": 4, "sg": 2, "sb": 2, "sd": 2, "td": 2},
	},
}

var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Main entry point.
## enabled_obstacles: Array of keys (e.g. ["fd", "sg"]), Dictionary of counts (e.g. {"fd": 2}), or null.
## Returns {"level": Dictionary, "meta": Dictionary} or empty Dictionary {} on failure.
func generate_level(
	difficulty: String = "medium",
	enabled_obstacles = null,
	cols_override: int = -1,
	rows_override: int = -1,
	max_attempts: int = 2000
) -> Dictionary:
	if not DIFFICULTIES.has(difficulty):
		push_error("Unknown difficulty: " + difficulty)
		return {}

	var cfg: Dictionary = DIFFICULTIES[difficulty]
	var obs: Dictionary = _resolve_obstacle_counts(difficulty, enabled_obstacles)
	var min_m: int = cfg["moves"].x
	var max_m: int = cfg["moves"].y

	for _attempt in range(max_attempts):
		var w: int = cols_override if cols_override > 0 else _rng.randi_range(cfg["cols"].x, cfg["cols"].y)
		var h: int = rows_override if rows_override > 0 else _rng.randi_range(cfg["rows"].x, cfg["rows"].y)

		# Build bordered grid (0 = floor, 1 = wall)
		var grid: Array = []
		var interior: Array[Vector2i] = []
		for r in range(h):
			var row: PackedByteArray = PackedByteArray()
			row.resize(w)
			for c in range(w):
				if r == 0 or r == h - 1 or c == 0 or c == w - 1:
					row[c] = 1
				else:
					row[c] = 0
					interior.append(Vector2i(r, c))
			grid.append(row)

		# Scatter internal walls
		var wall_count: int = int(interior.size() * cfg["wall_ratio"])
		for cell in _sample(interior, wall_count):
			grid[cell.x][cell.y] = 1

		var open_cells: Array[Vector2i] = []
		for cell in interior:
			if grid[cell.x][cell.y] == 0:
				open_cells.append(cell)

		var reserved: Dictionary = {} # Vector2i -> true

		# 1. Place shifting obstacles first with guaranteed 3-tile clear corridors
		var sb_placed: Array = _place_shifting_obstacles(grid, obs["sb"], open_cells, reserved)
		if sb_placed.size() < obs["sb"]:
			continue
		var sd_placed: Array = _place_shifting_obstacles(grid, obs["sd"], open_cells, reserved)
		if sd_placed.size() < obs["sd"]:
			continue

		# 2. Place remaining entities on unreserved open tiles
		var remaining: Array[Vector2i] = []
		for cell in open_cells:
			if not reserved.has(cell):
				remaining.append(cell)

		var needed: int = 4 + obs["fd"] + (2 * obs["sg"]) + obs["td"]
		if remaining.size() < needed:
			continue

		var picked: Array = _sample(remaining, needed)
		var idx: int = 0
		var a_pos: Vector2i = picked[idx]; var b_pos: Vector2i = picked[idx + 1]; idx += 2
		var e1: Vector2i = picked[idx]; var e2: Vector2i = picked[idx + 1]; idx += 2

		var fd_cells: Array[Vector2i] = []
		var danger_set: Dictionary = {}
		for i in range(obs["fd"]):
			var cell: Vector2i = picked[idx + i]
			fd_cells.append(cell)
			danger_set[cell] = true
		idx += obs["fd"]

		var gates: Array = [] # Array of [gate_pos, switch_pos]
		for _i in range(obs["sg"]):
			gates.append([picked[idx], picked[idx + 1]])
			idx += 2

		var td_cells: Array[Vector2i] = []
		for i in range(obs["td"]):
			td_cells.append(picked[idx + i])
		idx += obs["td"]

		# 3. Solve with BFS
		var result: Dictionary = solve_level(grid, a_pos, b_pos, e1, e2, danger_set, gates)
		if result.is_empty():
			continue
		if result["length"] < min_m or result["length"] > max_m or result["stalls"] < cfg["min_stalls"]:
			continue

		# 4. Build exact JSON-compatible Dictionary
		var sb_out: Array = []
		for item in sb_placed:
			var pt: Array = _tile_center(item[0], item[1])
			sb_out.append([pt[0], pt[1], item[2], TILE, TILE, TILE])

		var sd_out: Array = []
		for item in sd_placed:
			var pt: Array = _tile_center(item[0], item[1])
			sd_out.append([pt[0], pt[1], item[2], TILE, TILE, TILE])

		var sg_out: Array = []
		for g in gates:
			var gp: Array = _tile_center(g[0].x, g[0].y)
			var sp: Array = _tile_center(g[1].x, g[1].y)
			sg_out.append([gp[0], gp[1], sp[0], sp[1], TILE, TILE, TILE, TILE])

		var fd_out: Array = []
		for cell in fd_cells:
			var pt: Array = _tile_center(cell.x, cell.y)
			fd_out.append([pt[0], pt[1], TILE, TILE])

		var td_out: Array = []
		for cell in td_cells:
			var pt: Array = _tile_center(cell.x, cell.y)
			td_out.append([pt[0], pt[1], TILE, TILE])

		var pa: Array = _tile_center(a_pos.x, a_pos.y)
		var pb: Array = _tile_center(b_pos.x, b_pos.y)
		var pe1: Array = _tile_center(e1.x, e1.y)
		var pe2: Array = _tile_center(e2.x, e2.y)

		var level_data: Dictionary = {
			"w": [[0, 0], [int(w * TILE + 2.0 * MARGIN), int(h * TILE + 2.0 * MARGIN)]],
			"p": [[int(pa[0]), int(pa[1])], [int(pb[0]), int(pb[1])]],
			"e": [[int(pe1[0]), int(pe1[1])], [int(pe2[0]), int(pe2[1])]],
			"o": {
				"fb": _merge_fixed_blocks(grid, w, h),
				"sb": sb_out,
				"sg": sg_out,
				"fd": fd_out,
				"sd": sd_out,
				"td": td_out,
			}
		}

		# 5. Self-validate before returning
		var validation: Dictionary = validate_level(level_data)
		if not validation["valid"]:
			continue

		return {
			"level": level_data,
			"meta": {
				"difficulty": difficulty,
				"grid_size": [w, h],
				"par_moves": result["length"],
				"wall_stalls": result["stalls"],
				"obstacles": obs,
				"solution": result["moves"],
			}
		}

	return {}


## BFS solver over bit-packed state (ar, ac, br, bc, gate_mask).
func solve_level(
	grid: Array,
	a_start: Vector2i,
	b_start: Vector2i,
	e1: Vector2i,
	e2: Vector2i,
	danger_set: Dictionary,
	gates: Array,
	max_states: int = 50000
) -> Dictionary:
	var init_mask: int = (1 << gates.size()) - 1
	if _is_win(a_start, b_start, e1, e2):
		return {"moves": [], "length": 0, "stalls": 0}

	var gate_positions: Dictionary = {}
	var switch_positions: Dictionary = {}
	for i in range(gates.size()):
		gate_positions[gates[i][0]] = i
		switch_positions[gates[i][1]] = i

	var start_key: int = _pack_state(a_start, b_start, init_mask)
	var queue: PackedInt64Array = PackedInt64Array([start_key])
	var head: int = 0

	# parent[key] = [prev_key, move_char, was_stall]
	var parent: Dictionary = {start_key: [-1, "", false]}

	while head < queue.size():
		if parent.size() > max_states:
			return {}

		var curr_key: int = queue[head]
		head += 1

		var a := Vector2i(curr_key & 31, (curr_key >> 5) & 31)
		var b := Vector2i((curr_key >> 10) & 31, (curr_key >> 15) & 31)
		var mask: int = curr_key >> 20

		for move_char in DIRS.keys():
			var d: Vector2i = DIRS[move_char]
			var na: Vector2i = a + d
			var nb: Vector2i = b + d

			if _is_blocked(grid, na, mask, gate_positions):
				na = a
			if _is_blocked(grid, nb, mask, gate_positions):
				nb = b

			if na == nb:
				if na == b:
					na = a
				elif nb == a:
					nb = b

			if danger_set.has(na) or danger_set.has(nb):
				continue

			var new_mask: int = mask
			for pos in [na, nb]:
				if switch_positions.has(pos):
					var idx: int = switch_positions[pos]
					if gates[idx][0] != na and gates[idx][0] != nb:
						new_mask ^= (1 << idx)

			var next_key: int = _pack_state(na, nb, new_mask)
			if parent.has(next_key):
				continue

			var was_stall: bool = (na == a) != (nb == b)
			parent[next_key] = [curr_key, move_char, was_stall]

			if _is_win(na, nb, e1, e2):
				var moves: Array[String] = []
				var stalls: int = 0
				var trace: int = next_key
				while parent[trace][0] != -1:
					var entry: Array = parent[trace]
					moves.append(entry[1])
					if entry[2]:
						stalls += 1
					trace = entry[0]
				moves.reverse()
				return {"moves": moves, "length": moves.size(), "stalls": stalls}

			queue.append(next_key)

	return {}


## Independent AABB self-validator for bounds, overlaps, and shifting clearance.
func validate_level(level_data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var w_min: Array = level_data["w"][0]
	var w_max: Array = level_data["w"][1]
	var fb_rects: Array = level_data["o"]["fb"]

	if level_data["p"].size() != 2 or level_data["e"].size() != 2:
		errors.append("Level must have 2 players and 2 exits.")

	for group in [level_data["p"], level_data["e"]]:
		for pt in group:
			var rect := [float(pt[0]), float(pt[1]), TILE, TILE]
			if not _in_bounds(rect, w_min, w_max):
				errors.append("Entity out of bounds at " + str(pt))
			if _overlaps_any(rect, fb_rects):
				errors.append("Entity overlaps fb at " + str(pt))

	for key in ["fd", "td"]:
		for rect in level_data["o"][key]:
			if _overlaps_any(rect, fb_rects):
				errors.append("%s overlaps fb" % key)

	for sg in level_data["o"]["sg"]:
		if _overlaps_any([sg[0], sg[1], sg[4], sg[5]], fb_rects):
			errors.append("sg gate overlaps fb")
		if _overlaps_any([sg[2], sg[3], sg[6], sg[7]], fb_rects):
			errors.append("sg switch overlaps fb")

	for key in ["sb", "sd"]:
		for item in level_data["o"][key]:
			var x: float = item[0]; var y: float = item[1]
			var d: int = int(item[2])
			var bw: float = item[3]; var bh: float = item[4]
			if _overlaps_any([x, y, bw, bh], fb_rects):
				errors.append("%s overlaps fb" % key)
			var offsets: Array = [[0.0, -TILE], [0.0, TILE]] if d == 0 else [[-TILE, 0.0], [TILE, 0.0]]
			for off in offsets:
				if _overlaps_any([x + off[0], y + off[1], bw, bh], fb_rects):
					errors.append("%s collides with fb along travel path" % key)

	return {"valid": errors.is_empty(), "errors": errors}


# --- Helpers ---

func _pack_state(a: Vector2i, b: Vector2i, mask: int) -> int:
	return a.x | (a.y << 5) | (b.x << 10) | (b.y << 15) | (mask << 20)

func _is_win(a: Vector2i, b: Vector2i, e1: Vector2i, e2: Vector2i) -> bool:
	return (a == e1 and b == e2) or (a == e2 and b == e1)

func _is_blocked(grid: Array, pos: Vector2i, mask: int, gate_positions: Dictionary) -> bool:
	if grid[pos.x][pos.y] == 1:
		return true
	if gate_positions.has(pos) and (mask & (1 << gate_positions[pos])) != 0:
		return true
	return false

func _tile_center(r: int, c: int) -> Array:
	return [MARGIN + c * TILE + TILE * 0.5, MARGIN + r * TILE + TILE * 0.5]

func _merge_fixed_blocks(grid: Array, w: int, h: int) -> Array:
	var blocks: Array = []
	for r in range(h):
		var c: int = 0
		while c < w:
			if grid[r][c] == 1:
				var start: int = c
				while c < w and grid[r][c] == 1:
					c += 1
				var width: float = (c - start) * TILE
				var cx: float = MARGIN + start * TILE + width * 0.5
				var cy: float = MARGIN + r * TILE + TILE * 0.5
				blocks.append([cx, cy, width, TILE])
			else:
				c += 1
	return blocks

func _place_shifting_obstacles(grid: Array, count: int, open_cells: Array[Vector2i], reserved: Dictionary) -> Array:
	var placed: Array = []
	if count <= 0:
		return placed

	var candidates: Array[Vector2i] = []
	for cell in open_cells:
		if not reserved.has(cell):
			candidates.append(cell)
	_shuffle(candidates)

	for cell in candidates:
		if placed.size() == count:
			break
		if reserved.has(cell):
			continue
		var r: int = cell.x; var c: int = cell.y
		var valid_dirs: Array[int] = []
		if grid[r - 1][c] == 0 and grid[r + 1][c] == 0 and not reserved.has(Vector2i(r - 1, c)) and not reserved.has(Vector2i(r + 1, c)):
			valid_dirs.append(0)
		if grid[r][c - 1] == 0 and grid[r][c + 1] == 0 and not reserved.has(Vector2i(r, c - 1)) and not reserved.has(Vector2i(r, c + 1)):
			valid_dirs.append(1)
		if valid_dirs.is_empty():
			continue

		var d: int = valid_dirs[_rng.randi_range(0, valid_dirs.size() - 1)]
		placed.append([r, c, d])
		reserved[cell] = true
		if d == 0:
			reserved[Vector2i(r - 1, c)] = true
			reserved[Vector2i(r + 1, c)] = true
		else:
			reserved[Vector2i(r, c - 1)] = true
			reserved[Vector2i(r, c + 1)] = true

	return placed

func _resolve_obstacle_counts(difficulty: String, enabled_obstacles) -> Dictionary:
	var defaults: Dictionary = DIFFICULTIES[difficulty]["obs"]
	var counts: Dictionary = {}
	for k in OBSTACLE_KEYS:
		counts[k] = 0

	if enabled_obstacles is Dictionary:
		for k in enabled_obstacles.keys():
			if counts.has(k):
				counts[k] = maxi(0, int(enabled_obstacles[k]))
	elif enabled_obstacles is Array:
		for k in enabled_obstacles:
			if counts.has(k):
				counts[k] = defaults.get(k, 1)
	return counts

func _rects_overlap(r1: Array, r2: Array) -> bool:
	return (absf(r1[0] - r2[0]) < (r1[2] + r2[2]) * 0.5 - 0.001 and
			absf(r1[1] - r2[1]) < (r1[3] + r2[3]) * 0.5 - 0.001)

func _overlaps_any(rect: Array, list: Array) -> bool:
	for other in list:
		if _rects_overlap(rect, other):
			return true
	return false

func _in_bounds(rect: Array, w_min: Array, w_max: Array) -> bool:
	return (rect[0] - rect[2] * 0.5 >= w_min[0] and rect[0] + rect[2] * 0.5 <= w_max[0] and
			rect[1] - rect[3] * 0.5 >= w_min[1] and rect[1] + rect[3] * 0.5 <= w_max[1])

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _sample(arr: Array, k: int) -> Array:
	var copy: Array = arr.duplicate()
	_shuffle(copy)
	return copy.slice(0, k)
