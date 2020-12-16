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
	match state:
		'start': startState()
		_: startState()

func startState():
	var c = Conversation.new()
	
	c.character('helper', '{helperName}', 'secretary')
	c.speaking('helper')
	c.page("""
Master, you've arrived ahead of schedule! 
Please forgive the disarray, I have not yet had time to complete preparations!

I have made your office ready, but I fear I've run into trouble recruiting a work party from the nearby village so that the remaining work can get under way.
Actually...perhaps your authority would be useful here?

If you'll follow me to your office I have prepared a requisition, it lacks only your signature.""")
	c.speaking(null)
	c.input('But first - how should we address you?', self, 'on_input_player_name')
	c.clear()
	c.speaking('helper')
	c.text("""Ah, {playerName}, of course! Well, as I was saying - please allow me to show you to your office.\n\nIf you will just follow me...""")
	c.cmd(self, 'direct_to_office')
	
	yield(c.run(), 'completed')
	print('Finished the conversation')
	
func on_input_player_name(playerName):
	#var playerName = yield(Event.textInterface, 'input_enter')
	if playerName.dedent() == '': 
		playerName = 'Master'
	GameState.settings['playerName'] = playerName
	GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_OFFICE
	
func direct_to_office():	
	var locationsFolder:OrganizerFolder = UI.new_folder('Locations', true)
	locationsFolder.canDelete = false
	locationsFolder.canDrag = false
	UI.leftOrganizer.add_item_top(locationsFolder)
	var officeItem:OrganizerEntry = UI.new_item('{playerName}\'s Office'.format(GameState.settings), {'cmd':'scene', 'scene':'office'})
	officeItem.canDelete = false
	locationsFolder.add_item_bottom(officeItem)
	officeItem.call_attention()
