class_name LevelData

var windowSize: TwoPointPosition

var playersLocations: Array[SinglePointPosition]

var exitsLocations: Array[SinglePointPosition]

#obstacles
var fixedBlocksLocations: Array[SinglePointPosition]
var shiftingBlocksLocations: Array[SinglePointPosition]

var signalGatesLocations: Array[SignalGateData]

var fixedDangerZonesLocations: Array[SinglePointPosition]
var shiftingDangerZonesLocations: Array[SinglePointPosition]
var timedDangerZonesLocations: Array[SinglePointPosition]

func _to_string() -> String:
	return '''
	Window Size - 
	'''
