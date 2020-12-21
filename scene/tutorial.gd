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
	print('Resetting state for ', GameState.quest.get(Quest.Q_TUTORIAL))
	match GameState.quest.get(Quest.Q_TUTORIAL):
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
	GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_OFFICE
	setupState()
	
func direct_to_office():
	
	var mainOrg = load("res://ui/organizer/OrganizerData.gd").new()
	mainOrg.add_entry('Settings', {'noDel':true, 'noDrag':true, 'noEdit':true}, null, 'OrganizerFolder')
	mainOrg.add_entry('Settings/Quicksave', {'cmd':'quicksave', 'noDel':true, 'noDrag':true, 'noEdit':true}, 'quicksave')
	mainOrg.add_entry('Settings/Quickload', {'cmd':'quickload', 'noDel':true, 'noDrag':true, 'noEdit':true}, 'quickload')
	mainOrg.add_entry('Locations', {'noEdit':true,'isOpen':true,'noDelete':true}, null, 'OrganizerFolder')
	mainOrg.add_entry('Locations/Sacred School', {'noEdit':true,'isOpen':true,'noDelete':true}, null, 'OrganizerFolder')
	mainOrg.add_entry('Locations/Sacred School/'+'{playerName}\'s Office'.format(GameState.settings), 
		 {'cmd':'scene', 'scene':'office'}, 'gotoOffice')
	
	GameState.add_organizer('main', mainOrg)
	UI.leftOrganizer.refresh_organizer_data(GameState.get_organizer_data('main'))
	UI.leftOrganizer.visible = true
	yield(get_tree(), 'idle_frame')
	var officeItem = UI.leftOrganizer.get_entry_by_id('gotoOffice')
	officeItem.call_attention()
	UI.call_attention_from_right(officeItem)
	officeItem.set_no_delete(true)
