extends Node

var OrganizerData = load("res://ui/organizer/OrganizerData.gd")

var UI
var curScene = null
var bootstrapScene = null # Name of the scene to load at the start of GameScene. Used when starting a fresh game 
var loadingSaveFile = null # Name of the save file to load at the start of GameScene. Used when restoring the game from the title screen, or other times when the GameScene isn't loaded

var settings = {
	'playerName': 'Master',
	'schoolName': "Heaven's Shadow",
	'helperName': 'Ren Xiu',
}

var quest = {
	'tutorial':'start'
}

var resources = {
	"coin": 500
}

# Translation from resources (ex: from the results of decrees) into human-friendly names
# n: name (human-friendly name)
# d: description
# hide: (should this be hidden from decree results)
# levels: [[-50, 'extremely low'], [-25, 'very low'], [-10, 'low'], [10, 'neutral'], [25, 'high'], [50, 'very high'], 'extremely high']
# transient: If true, this resource disappears after time passes - it must be used immediately. For example, "unskilled labor" or a temporary weather phenomenon.
# suffix: optional, added after a numerical count of the resource if present; ex "suffix":"man-day" will print "3 man-days" instead of "3" when printing an amount of the resource
# psuffix: optional, added after a numerical count of the resource if present; normally the "suffix" is made plural by adding 's' to the end, but if that's incorrect you can
#		   provide psuffix to indicate. Ex: "suffix":"vortex","psuffix":"vortices" will result in "1 vortex" but "3 vortices"
# entity: optional, if present then this resource represents some entity that will be spawned rather than a numerical value to be incremented. 
#		org: name of the organizer to spawn the entity into
#		folderId: id of the folder within the organizer; if not provided or the folder doesn't exist it will just spawn at the bottom of the organizer 
#		data: path to a JSON file containing the OrganizerDataEntry.data that should be loaded when this resource is received, or a .gd class that will be instantiated instead
#		idSeries: if provided, adds a new entry like "id_{idSeries}" to the global settings, and increments it by 1 every time an entity is created. Mainly for use in nameTemplate and organizerNames
#					when the entity is a location that requires its own location
var resourceData = {
	"coin": {"n":"jade chips", "d":"The coin of the common folk. While the Emperor's mandate suffices to requisition anything you truly need, gifts of jade will help avoid ill feelings."},
	"disciple": {"n":"disciple", "d":"A newly recruited disciple",
		"entity":{"org":"main", "folderId":"new", "data":"res://exemplar/ExemplarData.gd", "idSeries":"exemplar"}},
	"facility_trainingHall": {"n":"training hall", "d":"A facility for strengthening the body with physical training or combat practice.", 
		"entity":{"org":"main", "folderId":"sacredSchool","data":"res://data/location/trainingHall.json", "idSeries":"trainingHall", "nameTemplate":"Training Hall {id_trainingHall}"}},
	"laborAdmin": {"n":"bureaucratic labor", "d":"Work performed by professional bureaucrats and functionaries.", "transient":true, "suffix":"man-day"},
	"laborScribe": {"n":"scribe labor", "d":"Work performed by skilled scribes.", "transient":true, "suffix":"man-day"},
	"laborUnskilled": {"n":"unskilled labor", "d":"Unskilled labor provided by work crews.", "transient":true, "suffix":"man-day"},
	"workCrew": {"n":"workers", "d":"Work crews perform common manual labor that is beneath the station of disciples and examplars - farming, construction, and so forth.", "suffix":"crew",
		"entity":{"org":"main", "folderId":"new", "data":"res://data/producer/workCrew.json"} },
	"villageDiplomacy": {"n":"villager reaction", "levels":[[-60, "infuriated"], [-30, "resentful"], [-15, "insulted"], [-5, "irritated"], [5, "neutral"], [15, "pleased"], [30, "happy"], [60, "honored"], "ecstatic"]},
}

var _organizers = {}

var attentionTimer:Timer

func _ready():
	attentionTimer = Timer.new()
	attentionTimer.one_shot = false
	attentionTimer.autostart = true
	add_child(attentionTimer)
	attentionTimer.start(0.1)

func get_resource_name(resourceId):
	var resource = resourceData.get(resourceId, {})
	return resource.get('n', resourceId)

func get_resource_description(resourceId):
	var resource = resourceData.get(resourceId, {})
	return resource.get('d')

func get_resource_level(resourceId, value):
	var resource = resourceData.get(resourceId, {})
	var levels = resource.get('levels')
	if levels:
		for level in levels:
			if level is String: return level
			if value <= level[0]: return level[1]
		return levels[levels.size()-1][1]
	var suffix
	if value == 1: 
		suffix = resource.get('suffix')
	else: 
		suffix = resource.get('psuffix')
		if !suffix: 
			suffix = resource.get('suffix')
			if suffix: suffix = suffix + 's'
	if suffix: value = str(value)+' '+suffix
	return str(value)

# Returns like: {"workers": {amt: 1, f_amt: "1 work crew", k: "numWorkers"}}
# Good for getting the human-friendly sortable keys for displaying resources in alphabetical order
func get_friendly_resource_map(resourceMap:Dictionary)->Dictionary:
	var retval = {}
	for k in resourceMap.keys():
		retval[get_resource_name(k)] = {"amt":resourceMap[k], "f_amt": get_resource_level(k, resourceMap[k]), "k": k}
	return retval

func reset_transient_resources():
	for k in resources.keys():
		if resourceData.get(k, {}).get('transient', false): resources.erase(k)

func add_resource(k, amt, source, opts={}):
	print('adding ', amt, ' ', k, ' from ', source)
	var data = resourceData.get(k, {})
	if data.get('entity'):
		var entityData = data.get('entity')
		if entityData.get('mergeId'): add_merged_entity_resource(k, amt, source, data)
		else: 
			amt = int(amt)
			if amt < 1: amt = 0
			if amt > 10: 
				printerr("Sorry, can't add more than 10 entities of a single type at a time...surely this must have been caused by a bug! type=", k, "; amt=", amt, "; src=", source)
				amt = 10
			var org = get_organizer_data(entityData.get('org', 'main'))
			#var entityCmdJson = Util.load_json_file(entityData.get('data',{}))
			for _i in range(amt):
				var nextId = k+"_"+str(randi())
				if entityData.get('idSeries'):
					nextId = settings.get('id_'+entityData.get('idSeries'), 0) + 1
					settings['id_'+entityData.get('idSeries')] = nextId
					nextId = entityData.get('idSeries')+'_'+str(nextId)
				var newName
				if opts.has('name'): 
					newName = opts.get('name').format(settings)
				if !newName or newName.length() == 0:
					newName = entityData.get('nameTemplate', '').format(settings)
				if !newName or newName.length() == 0:
					newName = NameGenerator.generate(k)
				# Create the OrganizerDataEntry inside the OrganizerData. It will contain a copy of the data from the 
				# file referenced by entityData.get('data'), and that copy will be returned so we can further manipulate it
				var newEntry = org.add_entry(newName+'^isUnread', entityData.get('data'), opts.get('id', str(nextId)), entityData.get('folderId'), entityData.get('entryScene', 'OrganizerEntry'))
				if !newEntry or !newEntry.get('data'):
					return # no need to merge options if no data was returned!
				var loadedData = newEntry.get('data')
				if loadedData is Dictionary:
					loadedData['name'] = newName
					if loadedData.has('organizerName'): loadedData['organizerName'] = loadedData['organizerName'].format(settings)
					# our loadedData is a dictionary, let's merge any additional options that were passed into it...I guess!
					if opts:
						for opt in opts:
							loadedData[opt] = opts[opt]
				elif loadedData.has_method('on_resource_create'):
					loadedData.on_resource_create(newName, opts, nextId)
					var updatedName = loadedData.get_entity_name()
					newEntry['name'] = updatedName
					
	else:
		resources[k] = resources.get(k, 0) + amt

func add_merged_entity_resource(resourceName, amt, source, entityData):
	printerr('Not implemented yet')

func produce_resources():
	var addedResources = {}
	for organizerData in _organizers.values():
		var newResources = organizerData.collect_produced_resources()
		for k in newResources.keys():
			var amt = newResources.get(k, 0)
			addedResources[k] = addedResources.get(k, 0) + amt
			add_resource(k, amt, null)
	return addedResources

func consume_resource(resourceName, amt, projectName):
	resources[resourceName] = resources.get(resourceName, 0) - amt
	print(projectName, ' consumed ', amt, ' ', get_resource_name(resourceName))

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
	
func serialize_world()->String:
	UI.save_organizers()
	settings['leftOrganizerName'] = UI.leftOrganizer.organizerDataName
	settings['rightOrganizerName'] = UI.rightOrganizer.organizerDataName
	settings['uiTextInterface'] = UI.serialize_text_interface()
	var retval = {
		'settings':settings,
		'quest':quest,
		'organizers':{},
		'resources':resources
	}
	for k in _organizers.keys():
		if k == 'Null': continue
		var serializedOrganizer = _organizers[k].serialize()
		retval.organizers[k] = serializedOrganizer
	return to_json(retval)

func refresh_organizers():
	load_organizers(true)

func save_organizers():
	UI.save_organizers()

func load_organizers(skipSave=false):
	var leftOrganizerName = GameState.settings.get('leftOrganizerName', 'main')
	var rightOrganizerName = GameState.settings.get('rightOrganizerName')
	if leftOrganizerName: UI.load_left_organizer(leftOrganizerName, skipSave)
	if rightOrganizerName: UI.load_right_organizer(rightOrganizerName, skipSave)

func change_right_organizer(organizerName):
	if UI: UI.load_right_organizer(organizerName, false)

func deserialize_world(worldJson):
	UI.clear_inner_panel()
	if curScene: curScene.queue_free()
	var serializedWorld = parse_json(worldJson)
	settings = serializedWorld.settings
	quest = serializedWorld.get('quest', {})
	resources = serializedWorld.get('resources', {})
	_organizers = {}
	var dummyOrg = OrganizerData.new() # needed because gdscript 3 doesn't support self-reference of classes from static functions :eyeroll:
	for k in serializedWorld.organizers:
		var deserializedOrganizer = dummyOrg.deserialize(serializedWorld.organizers[k])
		_organizers[k] = deserializedOrganizer
	if UI:
		load_organizers(true)
		UI.deserialize_text_interface(settings.get('uiTextInterface'))
	loadScene(settings['curSceneName'], settings['curSceneSettings'])
		
func save_world(saveSlot, serializedWorld):
	var dir:Directory = Directory.new()
	dir.make_dir('user://save')
	var file = File.new()
	file.open("user://save/%s.dat"%saveSlot, File.WRITE)
	file.store_string(serializedWorld)
	file.close()

func load_world(saveSlot):
	randomize()
	var file:File = File.new()
	file.open("user://save/%s.dat"%saveSlot, File.READ)
	var content = file.get_as_text()
	file.close()
	deserialize_world(content)
	
func add_organizer(organizerName, organizerData):
	organizerData.name = organizerName
	_organizers[organizerName] = organizerData

func loadScene(newSceneName:String, newSceneData):
	Conversation.reset()
	UI.clear_inner_panel()
	if UI && UI.textInterface: UI.textInterface.reset()
	if curScene && curScene.has_method('shutdown_scene'): 
		curScene.shutdown_scene()
	if curScene: curScene.queue_free()
	var newScene = load('res://scene/'+newSceneName+'.tscn').instance()
	if newScene.has_method('startup_scene'): newScene.startup_scene(newSceneData)
	curScene = newScene
	settings['curSceneName'] = newSceneName
	settings['curSceneSettings'] = newSceneData
	Event.emit_signal("new_scene_loaded", newScene)

func get_organizer_data(organizerName:String):
	if !_organizers.has(organizerName):
		_organizers[organizerName] = OrganizerData.new()
		_organizers[organizerName].name = organizerName
	return _organizers[organizerName]

func add_popup(popup):
	UI.add_popup(popup)
	
func add_inner_panel_popup(popup):
	UI.clear_inner_panel()
	UI.add_inner_panel_popup(popup)

func run_command(cmd, data:Dictionary, sourceNode:Node=null):
	if cmd is Array:
		for c in cmd:
			run_command(cmd, data, sourceNode)
		return
	if cmd != 'item' and cmd != 'msg' and cmd != 'train' and cmd != 'trainBonus': 
		UI.clear_inner_panel()
	match cmd:
		'decreeGen': cmd_decree_gen(data, sourceNode)
		'scene': cmd_scene(data, sourceNode)
		'item': cmd_item(data, sourceNode)
		'msg': cmd_msg(data, sourceNode)
		'placeable': cmd_placeable(data, sourceNode)
		'quicksave': cmd_quicksave()
		'quickload': cmd_quickload()
		'train': cmd_item_train(data, sourceNode)
		_: printerr('Invalid command: ', cmd, '; data=', data, '; sourceNode=', sourceNode.name)

func cmd_decree_gen(data:Dictionary, sourceNode):
	save_organizers()
	var orgName = data.get('org').format(settings) # assume org is a string, and it might be a string like "{rightOrganizerName}" so we can create decrees that target your current location instead of a fixed location
	var folderId = data.get('folderId') # optional, the ID of the root folder to put this into, if it can be found - ex 'outbox'
	var entryId = data.get('entryId') # optional, the ID to apply to the new decree...probably need to use a template var for this to be useful
	if entryId: entryId = entryId.format(settings)
	var decreeJsonFile = data.get('decreeFile') # JSON file holding the decree we're going to build
	var decreeData = load("res://decree/DecreeData.gd").new()
	decreeData.init_from_file(decreeJsonFile)
	if data.get('gotoScene'): cmd_scene({'scene':data.get('gotoScene'), 'organizerName':orgName}, sourceNode)
	var targetOrg = GameState.get_organizer_data(orgName)
	targetOrg.add_entry(decreeData.projectName, decreeData, entryId, folderId)
	refresh_organizers()
	decreeData.on_organizer_entry_clicked(null) # simulate a click so the decree pops up
	
# msg - text to display on the popup
func cmd_msg(data:Dictionary, sourceNode):
	Event.emit_signal('msg_popup', data, sourceNode)
	
# msg - text to display on the popup
# produce - list of resources that are produced
func cmd_item(data:Dictionary, sourceNode):
	var produces = data.get('produce', {})
	var consumes = data.get('consume', {})
	var consumed = data.get('consumed', {})
	var friendlyProduces = get_friendly_resource_map(produces)
	var friendlyConsumes = get_friendly_resource_map(consumes)
	var friendlyConsumed = get_friendly_resource_map(consumed)

	var msg = Util.load_text_file(data.get('msg', ''))
	
	if consumes.size() > 0:
		var friendlyKeys = friendlyConsumes.keys()
		friendlyKeys.sort()
		var consumeNote = "Last week's consumption:\n"
		for k in friendlyKeys:
			consumeNote += "%s: %s/%s\n" % [k, friendlyConsumed.get(k, {}).get("amt",0), friendlyConsumes[k]["f_amt"]]
		msg = msg + '\n---\n' + consumeNote
		
	if produces.size() > 0: 
		var friendlyKeys = friendlyProduces.keys()
		friendlyKeys.sort()
		var productionNote = "Daily production:\n"
		if !data.get('active', true): 
			productionNote += "  --(production inactive, insufficent resources consumed!)--\n"
		for k in friendlyKeys:
			productionNote += "%s: %s\n" % [k, friendlyProduces[k]["f_amt"]]
		msg = msg + '\n---\n' + productionNote
	
	var popupData =  {
		"msg": msg,
	}
	if data.get('img'): popupData['img'] = data.get('img')
	
	Event.emit_signal('msg_popup', popupData, sourceNode)

func cmd_item_train(data:Dictionary, sourceNode):
	var msg = Util.load_text_file(data.get('msg', ''))
	var train = data.get('train', {})
	if train.size():
		msg += "\n\n---\n\nAllows exemplars to train in the following ways:\n"
		for trainEntry in train:
			msg += "   %s\n"%trainEntry.get('description',"(unknown training)")
	cmd_item({'msg':msg, 'img':data.get('img')}, sourceNode)
	
func cmd_placeable(data, sourceNode):
	var itemShadow:Sprite = Sprite.new()
	itemShadow.texture = load(data.get('img'))
	itemShadow.modulate.a = 0.5
	Event.emit_signal('place_item', itemShadow, data, sourceNode)

func cmd_quicksave():
	print('quicksaving')
	var world = serialize_world()
	print('World: ', world)
	save_world('quicksave', world)
	
func cmd_quickload():
	print('quickloading')
	load_world('quicksave')
	

# scene - name of the scene (not 'res://scene/office.tscn', but just 'office')
# deleteSourceNodeAfterTransition - usually for deleting a choice-type item from an Organizer after you click it
# keepCharacter - don't hide any character portrait that's currently displayed in the UI
# keepText - don't clear any text buffered in the UI
func cmd_scene(data:Dictionary, sourceNode):
	if sourceNode && data.get('deleteSourceNodeAfterTransition'): sourceNode.queue_free()
	if !data.get('keepCharacter'): Event.hide_character()
	if !data.get('keepText'): Event.clear_text()
	loadScene(data.get('scene'), data)
