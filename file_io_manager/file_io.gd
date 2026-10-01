class_name FileIO

static func readFile(fileName: String) -> String:
	var result: String = ""
	
	var fileExists := FileAccess.file_exists(fileName)
	print("file existence")
	print(fileExists)
	
	if fileExists:
		var fileRef = FileAccess.open(fileName, FileAccess.READ)
		result = fileRef.get_as_text()
		print("file content")
		print(result)
		
	return result
