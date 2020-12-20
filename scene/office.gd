extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()
	UI.load_right_organizer('office')

# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

# Check for any important quest states and setup as needed, may call setup_default() manually as well if needed
func setup_quest():
	if GameState.quest.get(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_OFFICE:
		var c = Conversation
		c.speaking('helper')
		c.text("""
This will be your office, {playerName}. From here you will administer the new school of the sacred arts - making personnel decisions, reviewing resource allocations, sending decrees, and receiving updates from your subordinates.

I have taken the liberty of drawing up your first decree - the drafting of a work party from the nearby villages. With these workers we can get started on the infrastructure we need to support our studies into the sacred arts.

Please take a look at your outbox to the right, where you will find the decree. Any decrees in your outbox at the end of the week will be carried out!'
""")
		c.cmd(self, 'setup_first_decree')
		yield(c.run(), 'completed')
		GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_FIRST_DECREE
		c.page('')
		c.speaking(null)
		c.clear()
		yield(c.run(), 'completed')
		return true # Make any changes you need here...
	return .setup_quest()

func setup_first_decree():
	var decreeData = load("res://decree/DecreeData.gd").new()
	decreeData.load_file("res://data/decree/work")
#	decreeData.add_choice('workers', 'Number of Workers', [
#		{'l':'one work crew', 'v':{'numWorkers':1, 'diplomacy':-10}},
#		{'l':'two work crews', 'v':{'numWorkers':2, 'diplomacy':-25}},
#		{'l':'three work crews', 'v':{'numWorkers':3, 'diplomacy':-65}}
#	])
#	decreeData.add_choice('giftSize', 'Size of Gift', [
#		{'l':'nominal', 'v':{'coin':-1}},
#		{'l':'small', 'v':{'coin':-5,'diplomacy':1}},
#		{'l':'mediocre', 'v':{'coin':-25,'diplomacy':4}},
#		{'l':'large', 'v':{'coin':-100,'diplomacy':15}},
#		{'l':'enormous', 'v':{'coin':-500,'diplomacy':70}},
#	])
#	decreeData.decreeTextTemplate = 'Workers are required! Send {workers} to the {schoolName}. A {giftSize} gift will be provided in return.\n\n---\n\nCoins: {coin}\nVillage diplomacy change: {diplomacy}'
#
	var officeOrg = load("res://ui/organizer/OrganizerData.gd").new()
	officeOrg.add_entry('Outbox:noEdit:isOpen/Work Orders:noEdit:isOpen/Raise Work Crew', 
		 decreeData.serialize(), 'tutorialFirstWorkOrder')
	officeOrg.add_entry('Inbox:noEdit/From the Emperor/Your mission', {'cmd':'msg', 'msg':"res://data/conv/emperor_your_mission.txt"})
	officeOrg.add_entry('Inbox:noEdit/History/On Sacred Science', {'cmd':'msg', 'msg':"""
- 
"""})
	GameState.add_organizer('office', officeOrg)
	UI.rightOrganizer.refresh_organizer_data(GameState.get_organizer_data('office'))
	yield(get_tree(), 'idle_frame')
	var workorder = UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder')
	workorder.call_attention()
