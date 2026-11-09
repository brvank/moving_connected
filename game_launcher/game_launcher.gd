extends Node

# Scene preloads
const PlayerScene = preload(FileNames.Player)
const FixedBlocksScene = preload(FileNames.FixedBlocks)
const ShiftingBlocksScene = preload(FileNames.ShiftingBlocks)
const ExitPointScene = preload(FileNames.ExitPoint)
const SignalGateScene = preload(FileNames.SignalGate)
const FixedDangerZoneScene = preload(FileNames.FixedDangerZone)
const ShiftingDangerZoneScene = preload(FileNames.ShiftingDangerZone)
const TimedDangerZoneScene = preload(FileNames.TimedDangerZone)
const GameDialogsScene = preload(FileNames.GameDialogs)
const TouchControlsScene = preload(FileNames.TouchControls)

# Camera: default/closest zoom (never zooms in past this) and the
# farthest it's allowed to zoom out, plus world-space breathing room kept
# around the players' bounding box when fitting them both in view.
const DEFAULT_ZOOM: Vector2 = Vector2(1.0, 1.0)
const MIN_ZOOM_SCALAR: float = 0.35
const CAMERA_PADDING: float = 160.0
const CAMERA_ZOOM_LERP_SPEED: float = 4.0

# Colors - Sci-Fi Cybernetic Palette
const BORDER_COLOR: Color = Color(0.05, 0.08, 0.16, 1.0)
const ARENA_BG_COLOR: Color = Color(0.02, 0.035, 0.07, 1.0)

# Runtime state
var _players: Array[Node2D] = []
var _camera: Camera2D
var _exit_points: Array = []
var _level_complete: bool = false
var _game_over: bool = false
var _dialogs: CanvasLayer
var _previous_clear_color: Color

func _ready() -> void:
	# Set viewport clear color to match border color for outer letterbox/surround
	_previous_clear_color = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(BORDER_COLOR)

	# Attach dialogs CanvasLayer overlay
	_dialogs = GameDialogsScene.instantiate()
	add_child(_dialogs)

	# Attach touch controls overlay (auto-hides on non-touch devices)
	var touch_controls = TouchControlsScene.instantiate()
	add_child(touch_controls)

	# Fetch level data through GameManager (fallback to FileNames.Level if standalone)
	var fileData: String = ""
	if get_node_or_null("/root/GameManager") != null:
		fileData = GameManager.get_current_level_json_data()
	else:
		fileData = FileIO.readFile(FileNames.Level)

	var levelData = LevelDataParser.parseLevelData(fileData)

	if levelData == null:
		push_error("Failed to parse level data")
		return

	_setupBackground(levelData)
	_setupWalls(levelData)
	_setupPlayers(levelData)
	_setupCamera(levelData)
	_setupBlocks(levelData)
	_setupExitPoints(levelData)
	_setupSignalGates(levelData)
	_setupDangerZones(levelData)

func _exit_tree() -> void:
	RenderingServer.set_default_clear_color(_previous_clear_color)
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.set_thruster_active(false)

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_thruster_sound()

func _update_thruster_sound() -> void:
	var is_moving = false
	if not _game_over and not _level_complete:
		for player in _players:
			if is_instance_valid(player) and player is CharacterBody2D and player.velocity.length_squared() > 100.0:
				is_moving = true
				break
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.set_thruster_active(is_moving)

# ── Players ───────────────────────────────────────────────────────────────────

func _setupPlayers(levelData: LevelData) -> void:
	for playerLoc in levelData.playersLocations:
		var playerInstance = PlayerScene.instantiate()
		playerInstance.position = playerLoc.position()
		add_child(playerInstance)
		_players.append(playerInstance)

func _disable_player_movement() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.set_physics_process(false)
			if player is CharacterBody2D:
				player.velocity = Vector2.ZERO

# ── Camera ────────────────────────────────────────────────────────────────────

func _setupCamera(levelData: LevelData) -> void:
	if _players.is_empty():
		return

	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.zoom = DEFAULT_ZOOM

	# Set camera limits from level bounds
	_camera.limit_left = int(levelData.windowSize.left)
	_camera.limit_top = int(levelData.windowSize.top)
	_camera.limit_right = int(levelData.windowSize.right)
	_camera.limit_bottom = int(levelData.windowSize.bottom)

	add_child(_camera)
	_camera.make_current()
	_camera.global_position = _playersCenter()

func _playersCenter() -> Vector2:
	var sum = Vector2.ZERO
	var count = 0
	for player in _players:
		if is_instance_valid(player):
			sum += player.global_position
			count += 1
	if count == 0:
		return Vector2.ZERO
	return sum / count

# Keeps both players on screen: recenters on their midpoint every physics
# frame and zooms out just enough to fit them (with padding), never zooming
# in past DEFAULT_ZOOM or out past MIN_ZOOM_SCALAR.
func _update_camera(delta: float) -> void:
	if _camera == null or _players.is_empty():
		return

	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for player in _players:
		if not is_instance_valid(player):
			continue
		var pos = player.global_position
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	if min_x == INF:
		return

	_camera.global_position = Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)

	var span_x = (max_x - min_x) + CAMERA_PADDING * 2.0
	var span_y = (max_y - min_y) + CAMERA_PADDING * 2.0
	var viewport_size = get_viewport().get_visible_rect().size

	var fit_zoom = min(viewport_size.x / span_x, viewport_size.y / span_y)
	fit_zoom = clampf(fit_zoom, MIN_ZOOM_SCALAR, DEFAULT_ZOOM.x)

	var target_zoom = Vector2(fit_zoom, fit_zoom)
	_camera.zoom = _camera.zoom.lerp(target_zoom, clampf(CAMERA_ZOOM_LERP_SPEED * delta, 0.0, 1.0))

# ── Background ────────────────────────────────────────────────────────────────

class SciFiGrid extends Node2D:
	var left: float
	var top: float
	var width: float
	var height: float

	func _draw() -> void:
		var col_grid = Color(0.0, 0.75, 1.0, 0.05)
		var col_major = Color(0.0, 0.85, 1.0, 0.12)
		var col_border = Color(0.0, 0.9, 1.0, 0.85)
		var step = 50.0

		# Holographic tactical matrix lines
		var x = 0.0
		while x <= width:
			var c = col_major if fmod(x, 200.0) == 0.0 else col_grid
			draw_line(Vector2(left + x, top), Vector2(left + x, top + height), c, 1.0)
			x += step

		var y = 0.0
		while y <= height:
			var c = col_major if fmod(y, 200.0) == 0.0 else col_grid
			draw_line(Vector2(left, top + y), Vector2(left + width, top + y), c, 1.0)
			y += step

		# Luminous inner perimeter containment shield
		draw_rect(Rect2(left, top, width, height), col_border, false, 2.0)

func _setupBackground(levelData: LevelData) -> void:
	var bg_container = Node2D.new()
	bg_container.name = "Background"
	bg_container.z_index = -10
	$Env.add_child(bg_container)
	$Env.move_child(bg_container, 0)

	var left = levelData.windowSize.left
	var right = levelData.windowSize.right
	var top = levelData.windowSize.top
	var bottom = levelData.windowSize.bottom
	var extent = 50000.0

	# 1. Inner arena playable area background
	var inner_poly = _create_rect_poly(
		Rect2(Vector2(left, top), Vector2(right - left, bottom - top)),
		ARENA_BG_COLOR
	)
	bg_container.add_child(inner_poly)

	# 2. Holographic tactical grid & neon perimeter
	var grid = SciFiGrid.new()
	grid.left = left
	grid.top = top
	grid.width = right - left
	grid.height = bottom - top
	bg_container.add_child(grid)

	# 3. Outer background (region outside the border), matching border color
	# Top outer rect
	var outer_top = _create_rect_poly(
		Rect2(Vector2(left - extent, top - extent), Vector2((right - left) + 2.0 * extent, extent)),
		BORDER_COLOR
	)
	bg_container.add_child(outer_top)

	# Bottom outer rect
	var outer_bottom = _create_rect_poly(
		Rect2(Vector2(left - extent, bottom), Vector2((right - left) + 2.0 * extent, extent)),
		BORDER_COLOR
	)
	bg_container.add_child(outer_bottom)

	# Left outer rect
	var outer_left = _create_rect_poly(
		Rect2(Vector2(left - extent, top), Vector2(extent, bottom - top)),
		BORDER_COLOR
	)
	bg_container.add_child(outer_left)

	# Right outer rect
	var outer_right = _create_rect_poly(
		Rect2(Vector2(right, top), Vector2(extent, bottom - top)),
		BORDER_COLOR
	)
	bg_container.add_child(outer_right)

func _create_rect_poly(rect: Rect2, color: Color) -> Polygon2D:
	var poly = Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		rect.position,
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		rect.position + rect.size,
		Vector2(rect.position.x, rect.position.y + rect.size.y)
	])
	return poly

# ── Walls ─────────────────────────────────────────────────────────────────────

func _setupWalls(levelData: LevelData) -> void:
	var walls = $Env/Walls

	var wallSize = 20
	var originOffset = wallSize/2
	var left = levelData.windowSize.left
	var right = levelData.windowSize.right
	var top = levelData.windowSize.top
	var bottom = levelData.windowSize.bottom

	#(1,1) and (100,100) -> (left, top) and (right, bottom)

	#top horizontal wall
	var spriteWallTop = Sprite2D.new()
	var textureWallTop = DrawableTexture2D.new()
	textureWallTop.setup(right - left, wallSize, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, BORDER_COLOR)
	spriteWallTop.texture = textureWallTop
	spriteWallTop.position = Vector2(left + (right - left)/2, top + originOffset)
	var csWallTop = CollisionShape2D.new()
	var sWallTop = RectangleShape2D.new()
	sWallTop.size = Vector2(right - left, wallSize)
	csWallTop.shape = sWallTop
	csWallTop.position = spriteWallTop.position

	#left vertical wall
	var spriteWallLeft = Sprite2D.new()
	var textureWallLeft = DrawableTexture2D.new()
	textureWallLeft.setup(wallSize, bottom - top, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, BORDER_COLOR)
	spriteWallLeft.texture = textureWallLeft
	spriteWallLeft.position = Vector2(left + originOffset, top + (bottom - top)/2)
	var csWallLeft = CollisionShape2D.new()
	var sWallLeft = RectangleShape2D.new()
	sWallLeft.size = Vector2(wallSize, bottom - top)
	csWallLeft.shape = sWallLeft
	csWallLeft.position = spriteWallLeft.position

	#bottom horizontal wall
	var spriteWallBottom = Sprite2D.new()
	var textureWallBottom = DrawableTexture2D.new()
	textureWallBottom.setup(right - left, wallSize, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, BORDER_COLOR)
	spriteWallBottom.texture = textureWallBottom
	spriteWallBottom.position = Vector2(left + (right - left)/2, bottom - originOffset)
	var csWallBottom = CollisionShape2D.new()
	var sWallBottom = RectangleShape2D.new()
	sWallBottom.size = Vector2(right - left, wallSize)
	csWallBottom.shape = sWallBottom
	csWallBottom.position = spriteWallBottom.position

	#right vertical wall
	var spriteWallRight = Sprite2D.new()
	var textureWallRight = DrawableTexture2D.new()
	textureWallRight.setup(wallSize, bottom - top, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, BORDER_COLOR)
	spriteWallRight.texture = textureWallRight
	spriteWallRight.position = Vector2(right - originOffset, top + (bottom - top)/2)
	var csWallRight = CollisionShape2D.new()
	var sWallRight = RectangleShape2D.new()
	sWallRight.size = Vector2(wallSize, bottom - top)
	csWallRight.shape = sWallRight
	csWallRight.position = spriteWallRight.position

	walls.add_child(spriteWallTop)
	walls.add_child(spriteWallLeft)
	walls.add_child(spriteWallBottom)
	walls.add_child(spriteWallRight)

	walls.add_child(csWallTop)
	walls.add_child(csWallLeft)
	walls.add_child(csWallBottom)
	walls.add_child(csWallRight)

# ── Blocks ────────────────────────────────────────────────────────────────────

func _setupBlocks(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	for fixedBlock in levelData.fixedBlocksLocations:
		var fbInstance = FixedBlocksScene.instantiate()
		fbInstance.width = fixedBlock.width
		fbInstance.height = fixedBlock.height
		fbInstance.position = fixedBlock.position()
		blocks.add_child(fbInstance)

	for shiftingBlock in levelData.shiftingBlocksLocations:
		var sbInstance = ShiftingBlocksScene.instantiate()
		sbInstance.movementDirection = shiftingBlock.shiftingDirection
		sbInstance.width = shiftingBlock.width
		sbInstance.height = shiftingBlock.height
		sbInstance.position = shiftingBlock.position()
		blocks.add_child(sbInstance)

# ── Exit Points ───────────────────────────────────────────────────────────────

func _setupExitPoints(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	for exitLoc in levelData.exitsLocations:
		var epInstance = ExitPointScene.instantiate()
		epInstance.position = exitLoc.position()
		epInstance.player_reached_exit.connect(_on_player_reached_exit)
		epInstance.player_left_exit.connect(_on_player_left_exit)
		_exit_points.append(epInstance)
		blocks.add_child(epInstance)

func _on_player_reached_exit(exit_point: Area2D, body: Node2D) -> void:
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play_portal_enter()
	_on_exit_state_changed(exit_point, body)

func _on_player_left_exit(exit_point: Area2D, body: Node2D) -> void:
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play_portal_leave()
	_on_exit_state_changed(exit_point, body)

func _on_exit_state_changed(_exit_point: Area2D, _body: Node2D) -> void:
	_check_win_condition()

func _check_win_condition() -> void:
	if _level_complete or _game_over:
		return
	# Win when ALL exit points are occupied by different players (one player per exit)
	var occupied_by: Array[Node2D] = []
	for ep in _exit_points:
		if not ep.is_occupied():
			return
		for occupant in ep.get_occupants():
			if occupant not in occupied_by:
				occupied_by.append(occupant)
	# Need at least as many unique players as exits
	if occupied_by.size() >= _exit_points.size():
		_on_level_complete()

func _on_level_complete() -> void:
	if _level_complete or _game_over:
		return
	_level_complete = true
	print("=== LEVEL COMPLETE! ===")
	_disable_player_movement()
	
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play_level_complete()

	if get_node_or_null("/root/GameManager") != null:
		GameManager.complete_level(GameManager.current_world, GameManager.current_level)
	
	var has_next: bool = false
	if get_node_or_null("/root/GameManager") != null:
		var next_info = GameManager.get_next_level_info()
		has_next = next_info.exists
	
	if _dialogs:
		_dialogs.show_level_complete(has_next)

# ── Signal Gates ──────────────────────────────────────────────────────────────

func _setupSignalGates(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	for gateData in levelData.signalGatesLocations:
		var sgInstance = SignalGateScene.instantiate()
		sgInstance.block_position = gateData.block_position
		sgInstance.switch_position = gateData.switch_position
		sgInstance.block_width = gateData.block_width
		sgInstance.block_height = gateData.block_height
		sgInstance.switch_width = gateData.switch_width
		sgInstance.switch_height = gateData.switch_height
		blocks.add_child(sgInstance)

# ── Danger Zones ──────────────────────────────────────────────────────────────

func _setupDangerZones(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	# Fixed danger zones (static red hazards)
	for fdLoc in levelData.fixedDangerZonesLocations:
		var fdInstance = FixedDangerZoneScene.instantiate()
		fdInstance.width = fdLoc.width
		fdInstance.height = fdLoc.height
		fdInstance.position = fdLoc.position()
		fdInstance.player_hit_danger.connect(_on_player_hit_danger)
		blocks.add_child(fdInstance)

	# Shifting danger zones (moving red hazards)
	for sdLoc in levelData.shiftingDangerZonesLocations:
		var sdInstance = ShiftingDangerZoneScene.instantiate()
		sdInstance.movementDirection = sdLoc.shiftingDirection
		sdInstance.width = sdLoc.width
		sdInstance.height = sdLoc.height
		sdInstance.position = sdLoc.position()
		sdInstance.player_hit_danger.connect(_on_player_hit_danger)
		blocks.add_child(sdInstance)

	# Timed danger zones (periodically active red hazards)
	for tdLoc in levelData.timedDangerZonesLocations:
		var tdInstance = TimedDangerZoneScene.instantiate()
		tdInstance.width = tdLoc.width
		tdInstance.height = tdLoc.height
		tdInstance.position = tdLoc.position()
		tdInstance.player_hit_danger.connect(_on_player_hit_danger)
		blocks.add_child(tdInstance)

func _on_player_hit_danger(_danger_zone: Area2D, _body: Node2D) -> void:
	if _level_complete or _game_over:
		return
	_game_over = true
	print("Player hit a danger zone! Showing Game Over dialog...")
	_disable_player_movement()
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play_hazard_breach()
		SoundManager.play_game_over()
	if _dialogs:
		_dialogs.show_game_over()
