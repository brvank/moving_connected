class_name LevelDataParser

static func parseLevelData(data: String) -> LevelData:
	var levelData: LevelData = null
	var json = JSON.new()
	var error = json.parse(data)
	if error == OK:
		var jsonData = json.data
		print("data received")
		print(jsonData)
		levelData = _createLevelDataObject(jsonData)
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", data, " at line ", json.get_error_line())
	return levelData

static func _createLevelDataObject(dict: Dictionary) -> LevelData:
	var levelData: LevelData = LevelData.new()
	
	#setting the window size
	if dict.w is Array && dict.w.size() == 2:
		var leftTop = _arrayToVector2(dict.w[0])
		var rightBottom = _arrayToVector2(dict.w[1])
		levelData.windowSize = TwoPointPosition.new(leftTop, rightBottom)
	
	#setting the players positions
	levelData.playersLocations = _extractSinglePointPositions(dict.p)
	#setting the exits locations
	levelData.exitsLocations = _extractSinglePointPositions(dict.e)
	
	#setting the obstacles
	levelData.fixedBlocksLocations = _extractSinglePointPositions(dict.o.fb)
	levelData.shiftingBlocksLocations = _extractSinglePointPositions(dict.o.sb, true)
	levelData.signalGatesLocations = _extractSignalGatePositions(dict.o.sg)
	levelData.fixedDangerZonesLocations = _extractSinglePointPositions(dict.o.fd)
	levelData.shiftingDangerZonesLocations = _extractSinglePointPositions(dict.o.sd, true)
	levelData.timedDangerZonesLocations = _extractSinglePointPositions(dict.o.td)
		
	return levelData

static func _extractSinglePointPositions(arr: Array, is_shifting: bool = false) -> Array[SinglePointPosition]:
	var resultSinglePointPosisions: Array[SinglePointPosition] = []
	for ele in arr:
		if ele is Array:
			if is_shifting:
				resultSinglePointPosisions.append(SinglePointPosition.new(_arrayToVector2(ele), ele[2]))
			else:
				resultSinglePointPosisions.append(SinglePointPosition.new(_arrayToVector2(ele)))
		pass
	return resultSinglePointPosisions

static func _arrayToVector2(arr: Array) -> Vector2:
	return Vector2(arr[0], arr[1])

static func _extractSignalGatePositions(arr: Array) -> Array[SignalGateData]:
	var result: Array[SignalGateData] = []
	for ele in arr:
		if ele is Array and ele.size() >= 4:
			var block_pos = Vector2(ele[0], ele[1])
			var switch_pos = Vector2(ele[2], ele[3])
			result.append(SignalGateData.new(block_pos, switch_pos))
	return result
