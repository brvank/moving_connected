class_name FileIO

static func readFile(fileName: String) -> String:
	var result: String = ""
	var fileExists := FileAccess.file_exists(fileName)
	if fileExists:
		var fileRef = FileAccess.open(fileName, FileAccess.READ)
		if fileRef != null:
			result = fileRef.get_as_text()
			fileRef.close()
	return result

static func writeFile(fileName: String, content: String) -> bool:
	var fileRef = FileAccess.open(fileName, FileAccess.WRITE)
	if fileRef == null:
		var err = FileAccess.get_open_error()
		push_error("FileIO: Failed to open %s for writing. Error: %d" % [fileName, err])
		return false
	fileRef.store_string(content)
	fileRef.close()
	return true
