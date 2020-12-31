extends Node2D
class_name LocationScene

var UI
var GameScene
var sceneData
var rightOrganizerName

func startup_scene(sceneData):
	if !sceneData: 
		return
	self.sceneData = sceneData
	rightOrganizerName = sceneData.get('organizerName')
	if sceneData is Dictionary:
		initialize_scene_data()

func initialize_scene_data():
	if !rightOrganizerName: return
	var organizerData = GameState.get_organizer_data(rightOrganizerName)
	# Some locations might start with equipment already available for installation
	for initEntry in sceneData.get('initEntries', []):
		if initEntry is String:
			initEntry = Util.load_json_file(initEntry)
		if initEntry is Dictionary:
#add_entry(path:String, data, id=null, folderId=null, entrySceneName:String='OrganizerEntry', position=-1):
			var newEntry = organizerData.add_entry(initEntry.get('initPath', '(unknown item)'), initEntry, initEntry.get('initId', null), initEntry.get('initEntrySceneName', 'OrganizerEntry'))
	sceneData.erase('initPath')
	sceneData.erase('initId')
	sceneData.erase('initEntrySceneName')
	sceneData.erase('initEntries')
	
func _ready():
	setup_base()
	if !setup_quest(): setup_default()

func setup_base():
	var organizerData
	if rightOrganizerName:
		organizerData = GameState.get_organizer_data(rightOrganizerName)
	else:
		organizerData = GameState.get_organizer_data(GameState.settings.get('rightOrganizerName'))
	if rightOrganizerName:
		GameState.change_right_organizer(rightOrganizerName)
	for organizerDataEntry in organizerData.entries:
		if organizerDataEntry is Dictionary:
			var itemData = organizerDataEntry.get('data')
			if !itemData or !itemData is Dictionary or !itemData.has('posX') or !itemData.has('posY') or !itemData.has('img'): continue
			var hover = itemData.get('hover', false)
			Event.emit_signal('restore_item_placement', itemData, hover)

func setupNewScene(ui, gameScene):
	self.UI = ui
	self.GameScene = gameScene

func setup_default():
	pass

func setup_quest():
	#if GameState.quest.get('placeholder') == 'condition':
	#	return true
	return false

func shutdown_scene():
	print('shutting down scene')
	UI.save_organizers()
	UI.clear_organizer()
	UI.textInterface.reset()
