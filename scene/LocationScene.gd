extends Node2D
class_name LocationScene

var UI
var GameScene

var rightOrganizerName

func startup_scene(sceneData):
	if !sceneData: return
	rightOrganizerName = sceneData.get('organizerName')

func _ready():
	setup_base()
	if !setup_quest(): setup_default()

func setup_base():
	if rightOrganizerName:
		GameState.change_right_organizer(rightOrganizerName)
	var organizerData
	if rightOrganizerName:
		organizerData = GameState.get_organizer_data(rightOrganizerName)
	else:
		organizerData = GameState.get_organizer_data(GameState.settings.get('rightOrganizerName'))
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
