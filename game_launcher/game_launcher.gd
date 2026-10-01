extends Node

const FixedBlocksScene = preload(FileNames.FixedBlocks)
const ShiftingBlocksScene = preload(FileNames.ShiftingBlocks)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("game launcher script")
	
	var fileData = FileIO.readFile(FileNames.Level)
	var levelData = LevelDataParser.parseLevelData(fileData)
	
	print(levelData)
	
	_setupWalls(levelData)
	_setupPlayers(levelData)
	_setupBlocks(levelData)
	
	pass

func _process(delta: float) -> void:

	pass

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
	spriteWallTop.position = Vector2((right - left)/2, top + originOffset)
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
	spriteWallLeft.position = Vector2(left + originOffset, (bottom - top)/2)
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
	spriteWallBottom.position = Vector2((right - left)/2, bottom - originOffset)
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
	spriteWallRight.position = Vector2(right - originOffset, (bottom - top)/2)
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
	pass

func _setupPlayers(levelData: LevelData) -> void:

	pass

func _setupBlocks(levelData: LevelData) -> void:
	var blocks = $Env/Blocks
	
	for fixedBlock in levelData.fixedBlocksLocations:
		var fbInstance = FixedBlocksScene.instantiate()
		fbInstance.position = fixedBlock.position()
		blocks.add_child(fbInstance)
		pass
	
	for shiftingBlock in levelData.shiftingBlocksLocations:
		var sbInstance = ShiftingBlocksScene.instantiate()
		sbInstance.movementDirection = shiftingBlock.shiftingDirection
		sbInstance.position = shiftingBlock.position()
		blocks.add_child(sbInstance)
		pass
	
	pass
