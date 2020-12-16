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
	Event.show_character('res://img/people/secretary.png')
	Event.write_text_with_breaks("""
Master, you've arrived ahead of schedule! 
Please forgive the disarray, I have not yet had time to complete preparations!

I have made your office ready, but I fear I've run into trouble recruiting a work party from the nearby village so that the remaining work can get under way.
Actually...perhaps your authority would be useful here?

Here, I have prepared a requisition, it lacks only your signature. But first - how should we address you?
> """)
	Event.textInterface.buff_input()
	var playerName = yield(Event.textInterface, 'input_enter')
	if playerName.dedent() == '': 
		playerName = 'Master'
		Event.write_text_with_breaks("...%s will be fine."%playerName)
	GameState.settings['playerName'] = playerName
	Event.textInterface.buff_text('\n\n')
	Event.write_text_with_breaks("""
Ah, {playerName}, of course! Well, as I was saying - let me show you to your office, where you will find your inbox.

""")
	GameState.quest['tutorial'] = 'officeIntro'
	
	yield(Event.textInterface, "buff_end")
	
	var locationsFolder:OrganizerFolder = UI.new_folder('Locations', true)
	locationsFolder.canDelete = false
	locationsFolder.canDrag = false
	UI.leftOrganizer.add_item_top(locationsFolder)
	var officeItem:OrganizerEntry = UI.new_item('{playerName}\'s Office'.format(GameState.settings), {'cmd':'scene', 'scene':'office'})
	officeItem.canDelete = false
	locationsFolder.add_item_bottom(officeItem)
	
	Event.write_text_with_breaks("""If you will just follow me...""")
	yield(Event.textInterface, "buff_end")
	officeItem.call_attention()
