extends Node2D

var state = 'start'
var UI
var GameScene

func _ready():
	setupState()

func setupNewScene(ui, gameScene):
	self.UI = ui
	self.GameScene = gameScene

func setupState():
	match GameState.get_quest_status(Quest.Q_TUTORIAL):
		Quest.Q_TUTORIAL_OFFICE: officeState()
		_: startState()

func startState():
	var c = Conversation
	UI.leftOrganizer.visible = false
	UI.rightOrganizer.visible = false
	UI.controlsContainer.visible = false
	UI.timePassContainer.visible = false
	# done by default now - c.character('helper', '{helperName}', 'secretary')
	c.speaking('helper')
	c.page("""
Master, you've arrived ahead of schedule! 
Please forgive the disarray, I have not yet had time to complete preparations!
I have made your office ready, but I fear I've run into trouble recruiting a work party from the nearby village so that the remaining work can get under way.
Actually...perhaps your authority would be useful here?

If you'll follow me to your office I have prepared a requisition, it lacks only your signature.""")
	c.speaking(null)
	c.input('But first - how should we address you?', self, 'on_input_player_name')
	yield(c.run(), 'completed')

func officeState():
	var c = Conversation
	c.clear()
	c.speaking('helper')
	c.text("""Ah, {playerName}, of course! Well, as I was saying - please allow me to show you to your office.\n\nIf you will just follow me...""")
	c.cmd(self, 'direct_to_office')
	
	yield(c.run(), 'completed')
	print('Finished the tutorial conversation')
	
func on_input_player_name(playerName):
	#var playerName = yield(Event.textInterface, 'input_enter')
	if playerName.dedent() == '': 
		playerName = 'Master'
	GameState.settings['playerName'] = playerName
	GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_OFFICE)
	setupState()
	
func direct_to_office():
	
	var mainOrg = load("res://ui/organizer/OrganizerData.gd").new()
	mainOrg.add_folder('Settings^noDelete^noDrag^noEdit', 'settings')
	mainOrg.add_entry('Quicksave^noDelete^noDrag^noEdit', {'cmd':'quicksave'}, 'quicksave', 'settings')
	mainOrg.add_entry('Quickload^noDelete^noDrag^noEdit', {'cmd':'quickload'}, 'quickload', 'settings')
	mainOrg.add_folder('New Arrivals^noEdit^noDelete', 'new')
	mainOrg.add_folder('Locations^noEdit^isOpen^noDelete', 'locations')
	mainOrg.add_folder('Sacred School^noEdit^isOpen^noDelete', 'sacredSchool', 'locations')
	mainOrg.add_entry('{playerName}\'s Office^noEdit^noDelete^isUnread'.format(GameState.settings), 
		 {'cmd':'scene', 'scene':'office', 'organizerName':'office'}, 'office', 'sacredSchool')
	
	GameState.add_organizer('main', mainOrg)
	UI.load_left_organizer('main', true)
#	UI.leftOrganizer.refresh_organizer_data(GameState.get_organizer_data('main'))
	UI.leftOrganizer.visible = true
	yield(get_tree(), 'idle_frame')
	var officeItem = UI.leftOrganizer.get_entry_by_id('office')
	officeItem.call_attention()
	UI.call_attention_from_right(officeItem)
	officeItem.set_no_delete(true)
