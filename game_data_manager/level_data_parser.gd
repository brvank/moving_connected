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
		if ele is Array and ele.size() >= 2:
			var pos = _arrayToVector2(ele)
			var shift_dir: int = 0
			var w: int = 20
			var h: int = 50
			if is_shifting:
				if ele.size() >= 3:
					shift_dir = int(ele[2])
				if ele.size() >= 5:
					w = int(ele[3])
					h = int(ele[4])
			else:
				if ele.size() >= 4:
					w = int(ele[2])
					h = int(ele[3])
			resultSinglePointPosisions.append(SinglePointPosition.new(pos, shift_dir, w, h))
	return resultSinglePointPosisions

static func _arrayToVector2(arr: Array) -> Vector2:
	return Vector2(arr[0], arr[1])

static func _extractSignalGatePositions(arr: Array) -> Array[SignalGateData]:
	var result: Array[SignalGateData] = []
	for ele in arr:
		if ele is Array and ele.size() >= 4:
			var block_pos = Vector2(ele[0], ele[1])
			var switch_pos = Vector2(ele[2], ele[3])
			var block_w: int = int(ele[4]) if ele.size() >= 8 else 20
			var block_h: int = int(ele[5]) if ele.size() >= 8 else 50
			var switch_w: int = int(ele[6]) if ele.size() >= 8 else 20
			var switch_h: int = int(ele[7]) if ele.size() >= 8 else 20
			result.append(SignalGateData.new(block_pos, switch_pos, block_w, block_h, switch_w, switch_h))
	return result
