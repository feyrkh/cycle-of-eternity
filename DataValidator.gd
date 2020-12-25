extends Node

func validate_all():
	print("Validating all data files")
	var startTime = OS.get_system_time_msecs()
	self.validate_json()
	var endTime = OS.get_system_time_msecs()
	print("Finished validating data files after ", (endTime-startTime), " ms")

func validate_json():
	print('Validating json...')
	dir_contents('res://data', '.json', 'check_json_loadable')
	print('Finished validating json')
	
func dir_contents(path, fileSuffix, validationCmd):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != '.' and file_name != '..':
				if dir.current_is_dir():
					#print("Found directory: " + path+'/'+file_name)
					dir_contents(path+'/'+file_name, fileSuffix, validationCmd)
				else:
					#print("Found file: " + path+'/'+file_name)
					if file_name.ends_with(fileSuffix):
						call(validationCmd, path+'/'+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func check_json_loadable(file):
	var json = Util.load_text_file(file)
	if json == null: 
		printerr(file, ": JSON couldn't be loaded - does the file exist?")
	var err = validate_json(json)
	if err:
		printerr(file, ": JSON couldn't be parsed - is it valid?  (", err, ")")
