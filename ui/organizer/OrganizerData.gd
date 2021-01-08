extends Resource
class_name OrganizerData

var name
var friendlyName
var entries = [] setget set_entries
var entryIds = {}
var organizer
var allowNewFolder = true
var allowDelete = true

var entryTypeIndex = {}
const entryTypes = ['exemplar', 'producer', 'training', 'consumer', 'project', 'location', 'technique']

func _init():
	refresh_entry_type_index()

func save():
	GameState.add_organizer(name, self)

func refresh_entry_type_index():
	for entryType in entryTypes:
		entryTypeIndex[entryType] = []
	for entry in entries:
		if entry.get('id'):
			entryIds[entry.get('id')] = entry
		index_entry(entry)
		
func refresh_organizer_if_loaded():
	GameState.refresh_organizers(name)

func index_entry(entry):
	# consumers
	if _get_consumer_data(entry) != null:
		entryTypeIndex['consumer'].append(entry)
	if _get_producer_data(entry) != null:
		entryTypeIndex['producer'].append(entry)
	if self._get_project_data(entry):
		entryTypeIndex['project'].append(entry)
	if entry.data and entry.data is Dictionary and entry.data.has('train') and entry.data.get('cmd','') != 'placeable':
		entryTypeIndex['training'].append(entry)
	if entry.data and entry.data is TrainingData:
		entryTypeIndex['training'].append(entry)
	if entry.data and entry.data is ExemplarData:
		entryTypeIndex['exemplar'].append(entry)
	if entry.data and entry.data is Dictionary and entry.data.get('cmd') == 'scene' and entry.data.get('organizerName'):
		entryTypeIndex['location'].append(entry)

func get_entries_with_type(entryType):
	return entryTypeIndex.get(entryType, [])

func set_entries(val):
	entryIds = {}
	if !val: entries = []
	entries = val
	refresh_entry_type_index()

func cloneFromActiveOrg(orgName):
	if !orgName: return
	var otherOrg = GameState.get_organizer_data(orgName)
	if !otherOrg: return
	name =  otherOrg.name
	friendlyName = otherOrg.friendlyName
	entries = otherOrg.entries
	entryIds = otherOrg.entryIds

func serialize():
	var serializedEntries = Array()
	var result = {
		'name':name,
		'f_name':friendlyName,
		'entries':serializedEntries
	}
	if !allowNewFolder: result['allowNewFolder'] = false
	if !allowDelete: result['allowDelete'] = false
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
				var deserData = load('res://decree/DecreeData.gd').new()
				deserData.deserialize(valData)
				valData = deserData
			Util.DATATYPE_EXEMPLAR:
				var deserData = load('res://exemplar/ExemplarData.gd').new()
				deserData.deserialize(valData)
				valData = deserData
	return valData
	
func deserialize(dict:Dictionary)->OrganizerData:
	var retval = get_script().new()
	retval.name = dict.name
	retval.friendlyName = dict.get('f_name', dict.name)
	var deserializedEntries = Array()
	for entry in dict.entries:
		var valData = entry.get('data',{})
		valData = deserialize_organizer_entry(valData)
		entry['data'] = valData
		deserializedEntries.append(entry)
	retval.entries = deserializedEntries
	retval.allowNewFolder = dict.get('allowNewFolder', true)
	retval.allowDelete = dict.get('allowDelete', true)
	refresh_entry_type_index()
	return retval
	
func get_entry_by_path(entryPath):
	for entry in entries:
		if entryPath == '/'+PoolStringArray(entry.path).join('/')+entry.name: return entry
	return null

func get_entry_by_id(entryId):
	return entryIds.get(entryId)
	
func delete_entry_by_id(entryId):
	var entry = get_entry_by_id(entryId)
	if entry:
		entries.erase(entry)

func add_entry(path:String, data, id=null, folderId=null, entrySceneName:String='OrganizerEntry', position=-1):
	if data && data is String && data.begins_with('res:'):
		if data.ends_with('.json'):
			data = Util.load_json_file(data)
		elif data.ends_with('.gd'):
			data = load(data).new()
	if data == null: data = {}
	var pathChunks:Array = path.split('/', false)
	var name = pathChunks.pop_back()
	pathChunks = Array(pathChunks) # it's actually a PoolStringArray at this point, which causes problems for concating later
	if folderId != null: 
		var fldr = entryIds.get(folderId)
		if fldr: 
			pathChunks = Array(fldr.get('path', [])) + [fldr.get('name')] + pathChunks
	var nameChunks = name.split('^', false)
	name = nameChunks[0]
	nameChunks.remove(0)
	var entryFlags = Util.build_entry_flags(nameChunks)
	var entry = OrganizerDataEntry.build(id, name, pathChunks, data, entrySceneName, entryFlags)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
	if position < 0 or position > entries.size(): 
		position = entries.size()
	entries.insert(position, entry)
	index_entry(entry)
	if id: entryIds[id] = entry
	return entry

func add_folder(path:String, id=null, folderId=null, data:Dictionary={}):
	if get_entry_by_id(id): return
	var pathChunks:Array = path.split('/', false)
	if folderId != null: 
		var fldr = entryIds.get(folderId)
		if fldr: 
			pathChunks = fldr.get('path', []) + [fldr.get('name')] + pathChunks
	var curPathChunks = []
	var finalPathChunk = pathChunks.pop_back()
	for pathChunk in pathChunks:
		var pathConfig = pathChunk.split('^', false)
		var n = pathConfig[0]
		pathConfig.remove(0)
		var curPath = (PoolStringArray(curPathChunks).join('/'))+'/'+n
		if get_entry_by_path(curPath) == null:
			var entryFlags = Util.build_entry_flags(pathConfig)
			var entry = OrganizerDataEntry.build(null, n, curPathChunks.duplicate(), data, 'OrganizerFolder', entryFlags)
			entries.append(entry)
			index_entry(entry)
		curPathChunks.append(n)
	# Build the final folder, which is basically the same as above but has an ID...
	#TODO: Refactor this so it's a recursive buildup instead of copy/paste...should be easy, but I can't focus right now thanks to dogs and just want to move on -_-
	var pathConfig = finalPathChunk.split('^', false)
	var n = pathConfig[0]
	pathConfig.remove(0)
	#var curPath = (PoolStringArray(curPathChunks).join('/'))+'/'+n
	var entryFlags = Util.build_entry_flags(pathConfig)
	var entry = OrganizerDataEntry.build(id, n, curPathChunks.duplicate(), data, 'OrganizerFolder', entryFlags)
	if id: 
		entryIds[id] = entry
	entries.append(entry)
	index_entry(entry)
	
func collect_resource_consumers():
	var results = []
	for entry in entryTypeIndex['consumer']:
		var consumerData = _get_consumer_data(entry)
		if consumerData: 
			results.append(consumerData)
	return results

func _get_consumer_data(entry):
	if !(entry is Dictionary) or !entry.has('data') or !(entry['data'] is Dictionary): 
		return null
	if entry.get('data', {}).has('consume'):
		return entry['data']

func collect_projects():
	var results = []
	for entry in entryTypeIndex['project']:
		if _get_project_data(entry):
			results.append(entry)
	return results

func _get_project_data(entry):
	var pathChunks = entry.get('path', [])
	if pathChunks.size() > 0 and pathChunks[0] == 'Outbox' and entry.get('data',{}).has_method('get_is_project') and entry.get('data').get_is_project():
		return entry
	return null

func collect_produced_resources():
	var results = {}
	for entry in entryTypeIndex['producer']:
		var products = _get_producer_data(entry)
		if products:
			for resource in products.keys():
				results[resource] = products[resource] + results.get(resource, 0)
	return results

func _get_producer_data(entry, ignoreActiveFlag=false):
	if !entry.get('data') or !(entry.get('data') is Dictionary): 
		return null # don't produce resources from non-Dictionary entries
	if !ignoreActiveFlag and !entry.get('data',{}).get('active', true): 
		return null
	return entry.get('data',{}).get('produce')
	
