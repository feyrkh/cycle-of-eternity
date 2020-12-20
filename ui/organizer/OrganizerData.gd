extends Resource
class_name OrganizerData

var name
var entries = []
var organizer

func serialize():
	return {
		'name':name,
		'entries':entries
	}

func deserialize(dict:Dictionary)->OrganizerData:
	var retval = get_script().new()
	retval.name = dict.name
	retval.entries = dict.entries
	return retval

func get_entry_by_path(entryPath):
	for entry in entries:
		if entryPath == entry.path: return entry
	return null

func remove_entry_by_path(entryPath):
	var entry = get_entry_by_path(entryPath)
	if entry: entries.remove(entry)

func add_entry(path:String, data, id=null, entrySceneName:String='OrganizerEntry', position=-1):
	if data == null: data = {}
	var pathChunks:Array = path.split('/', false)
	var name = pathChunks.pop_back()
	var entry = OrganizerDataEntry.build(id, name, pathChunks, data, entrySceneName)
	if position < 0 or position > entries.size(): position = entries.size()
	entries.insert(position, entry)

func add_folder(path:String, data:Dictionary):
	var pathChunks:Array = path.split('/', false)
	var curPathChunks = []
	for pathChunk in pathChunks:
		var curPath = curPathChunks.join('/')+'/'+pathChunk
		if get_entry_by_path(curPath) == null:
			var entry = OrganizerDataEntry.build(null, pathChunk, curPathChunks, data, 'OrganizerFolder')
			entries.append(entry)
		curPathChunks.append(pathChunk)
	
