extends Resource
class_name OrganizerData

var name
var entries = []
var organizer

func serialize():
	var serializedEntries = Array()
	var result = {
		'name':name,
		'entries':serializedEntries
	}
	for entry in entries:
		if !(entry['data'] is Dictionary): 
			entry = entry.duplicate()
			entry['data'] = entry['data'].serialize() 
		serializedEntries.append(entry)
	return result

# UGH, cyclic reference failures are annoying with static functions...see also GameState
func deserialize_organizer_entry(valData):
	if valData is Dictionary:
		var dataType = int(valData.get('dt', 0))
		match dataType:
			Util.DATATYPE_DICT: pass 
			Util.DATATYPE_DECREE:
				var deserData = DecreeData.new()
				deserData.deserialize(valData)
				valData = deserData
	return valData
	
func deserialize(dict:Dictionary)->OrganizerData:
	var retval = get_script().new()
	retval.name = dict.name
	var deserializedEntries = Array()
	for entry in dict.entries:
		var valData = entry.get('data',{})
		valData = deserialize_organizer_entry(valData)
		entry['data'] = valData
		deserializedEntries.append(entry)
	retval.entries = deserializedEntries
	return retval
	
func get_entry_by_path(entryPath):
	for entry in entries:
		if entryPath == entry.path: return entry
	return null

func remove_entry_by_path(entryPath):
	var entry = get_entry_by_path(entryPath)
	if entry: entries.remove(entry)

func add_entry(path:String, data, id=null, entrySceneName:String='OrganizerEntry', position=-1):
	if data && data is String && data.begins_with('res:'):
		data = Util.load_json_file(data)
	if data == null: data = {}
	var pathChunks:Array = path.split('/', false)
	var name = pathChunks.pop_back()
	var nameChunks = name.split('^', false)
	name = nameChunks[0]
	nameChunks.remove(0)
	var entryFlags = Util.build_entry_flags(nameChunks)
	var entry = OrganizerDataEntry.build(id, name, pathChunks, data, entrySceneName, entryFlags)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
	if position < 0 or position > entries.size(): position = entries.size()
	entries.insert(position, entry)

func add_folder(path:String, data:Dictionary):
	var pathChunks:Array = path.split('/', false)
	var curPathChunks = []
	for pathChunk in pathChunks:
		var curPath = curPathChunks.join('/')+'/'+pathChunk
		if get_entry_by_path(curPath) == null:
			var pathConfig = pathChunk.split('^', false)
			var name = pathConfig[0]
			pathConfig.remove(0)
			var entryFlags = Util.build_entry_flags(pathConfig)
			var entry = OrganizerDataEntry.build(null, pathChunk, curPathChunks, data, 'OrganizerFolder', entryFlags)
			entries.append(entry)
		curPathChunks.append(pathChunk)
	
func collect_projects():
	var results = []
	for entry in entries:
		var pathChunks = entry.get('path', [])
		if pathChunks.size() > 0 and pathChunks[0] == 'Outbox' and entry.get('data',{}).get('in', {}).size() > 0:
			results.append(entry)
	return results

func collect_produced_resources():
	var results = {}
	for entry in entries:
		var products = entry.get('data',{}).get('produce')
		if products and products.size() > 0:
			for resource in products.keys():
				results[resource] = products[resource] + results.get(resource, 0)
	return results
