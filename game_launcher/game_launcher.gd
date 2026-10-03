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

# Runtime state
var _players: Array[Node2D] = []
var _camera: Camera2D
var _current_camera_index: int = 0
var _exit_points: Array = []
var _level_complete: bool = false

func _ready() -> void:
	var fileData = FileIO.readFile(FileNames.Level)
	var levelData = LevelDataParser.parseLevelData(fileData)

	if levelData == null:
		push_error("Failed to parse level data")
		return

	_setupWalls(levelData)
	_setupPlayers(levelData)
	_setupCamera(levelData)
	_setupLine()
	_setupBlocks(levelData)
	_setupExitPoints(levelData)
	_setupSignalGates(levelData)
	_setupDangerZones(levelData)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		_cycle_camera()

# ── Players ───────────────────────────────────────────────────────────────────

func _setupPlayers(levelData: LevelData) -> void:
	for playerLoc in levelData.playersLocations:
		var playerInstance = PlayerScene.instantiate()
		playerInstance.position = playerLoc.position()
		add_child(playerInstance)
		_players.append(playerInstance)

# ── Camera ────────────────────────────────────────────────────────────────────

func _setupCamera(levelData: LevelData) -> void:
	if _players.is_empty():
		return

	# Create camera and attach to first player
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS

	# Set camera limits from level bounds
	_camera.limit_left = int(levelData.windowSize.left)
	_camera.limit_top = int(levelData.windowSize.top)
	_camera.limit_right = int(levelData.windowSize.right)
	_camera.limit_bottom = int(levelData.windowSize.bottom)

	_current_camera_index = 0
	_players[0].add_child(_camera)

func _cycle_camera() -> void:
	if _players.size() <= 1:
		return
	_current_camera_index = (_current_camera_index + 1) % _players.size()
	_camera.reparent(_players[_current_camera_index])
	_camera.position = Vector2.ZERO

# ── Line ──────────────────────────────────────────────────────────────────────

func _setupLine() -> void:
	var line = $Line2D
	line.set_tracked_nodes(_players)

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
	textureWallTop.setup(right - left, wallSize, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, Color(1,0.5,1))
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
	textureWallLeft.setup(wallSize, bottom - top, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, Color(1,0.5,1))
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
	textureWallBottom.setup(right - left, wallSize, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, Color(1,0.5,1))
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
	textureWallRight.setup(wallSize, bottom - top, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8, Color(1,0.5,1))
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
		fbInstance.position = fixedBlock.position()
		blocks.add_child(fbInstance)

	for shiftingBlock in levelData.shiftingBlocksLocations:
		var sbInstance = ShiftingBlocksScene.instantiate()
		sbInstance.movementDirection = shiftingBlock.shiftingDirection
		sbInstance.position = shiftingBlock.position()
		blocks.add_child(sbInstance)

# ── Exit Points ───────────────────────────────────────────────────────────────

func _setupExitPoints(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	for exitLoc in levelData.exitsLocations:
		var epInstance = ExitPointScene.instantiate()
		epInstance.position = exitLoc.position()
		epInstance.player_reached_exit.connect(_on_exit_state_changed)
		epInstance.player_left_exit.connect(_on_exit_state_changed)
		_exit_points.append(epInstance)
		blocks.add_child(epInstance)

func _on_exit_state_changed(_exit_point: Area2D, _body: Node2D) -> void:
	_check_win_condition()

func _check_win_condition() -> void:
	if _level_complete:
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
	_level_complete = true
	print("=== LEVEL COMPLETE! ===")

# ── Signal Gates ──────────────────────────────────────────────────────────────

func _setupSignalGates(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	for gateData in levelData.signalGatesLocations:
		var sgInstance = SignalGateScene.instantiate()
		sgInstance.block_position = gateData.block_position
		sgInstance.switch_position = gateData.switch_position
		blocks.add_child(sgInstance)

# ── Danger Zones ──────────────────────────────────────────────────────────────

func _setupDangerZones(levelData: LevelData) -> void:
	var blocks = $Env/Blocks

	# Fixed danger zones (static red hazards)
	for fdLoc in levelData.fixedDangerZonesLocations:
		var fdInstance = FixedDangerZoneScene.instantiate()
		fdInstance.position = fdLoc.position()
		fdInstance.player_hit_danger.connect(_on_player_hit_danger)
		blocks.add_child(fdInstance)

	# Shifting danger zones (moving red hazards)
	for sdLoc in levelData.shiftingDangerZonesLocations:
		var sdInstance = ShiftingDangerZoneScene.instantiate()
		sdInstance.movementDirection = sdLoc.shiftingDirection
		sdInstance.position = sdLoc.position()
		sdInstance.player_hit_danger.connect(_on_player_hit_danger)
		blocks.add_child(sdInstance)

	# Timed danger zones (periodically active red hazards)
	for tdLoc in levelData.timedDangerZonesLocations:
		var tdInstance = TimedDangerZoneScene.instantiate()
		tdInstance.position = tdLoc.position()
		tdInstance.player_hit_danger.connect(_on_player_hit_danger)
		blocks.add_child(tdInstance)

func _on_player_hit_danger(_danger_zone: Area2D, _body: Node2D) -> void:
	if _level_complete:
		return
	print("Player hit a danger zone! Restarting level...")
	get_tree().reload_current_scene()
