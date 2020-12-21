extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()
	UI.load_right_organizer('office')

# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

# Check for any important quest states and setup as needed, may call setup_default() manually as well if needed
func setup_quest()->bool:
	match GameState.quest.get(Quest.Q_TUTORIAL, ''):
		Quest.Q_TUTORIAL_OFFICE: 
			tutorial_office_intro()
			return true
		Quest.Q_TUTORIAL_FIRST_DECREE: 
			tutorial_first_decree()
			return true
		Quest.Q_TUTORIAL_DISCARD_RUBBISH:
			tutorial_discard_rubbish()
			return true
		Quest.Q_TUTORIAL_PASS_TIME:
			tutorial_pass_time()
			return true
	return false

func tutorial_office_intro():
	if GameState.quest.get(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_OFFICE:
		UI.rightOrganizer.visible = false
		UI.controlsContainer.visible = false
		UI.timePassContainer.visible = false
		var c = Conversation
		c.speaking('helper')
		c.text("""
This will be your office, {playerName}. From here you will administer the new school of the sacred arts - making personnel decisions, reviewing resource allocations, sending decrees, and receiving updates from your subordinates.

I have taken the liberty of drawing up your first decree - the drafting of a work party from the nearby villages. With these workers we can get started on the infrastructure we need to support our studies into the sacred arts.

Please take a look at your outbox, where you will find the decree. Any decrees in your outbox at the end of the week will be carried out!'
""")
		c.cmd(self, 'setup_first_decree')
		yield(c.run(), 'completed')
		GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_FIRST_DECREE
		setup_quest()

func setup_first_decree():
	var decreeData = load("res://decree/DecreeData.gd").new()
	decreeData.init_from_file("res://data/decree/hireWorkCrew.json")
	var officeOrg = load("res://ui/organizer/OrganizerData.gd").new()
	officeOrg.add_entry('Outbox:noEdit:isOpen:noDelete/Raise Work Crew', decreeData.serialize(), 'tutorialFirstWorkOrder')
	officeOrg.add_entry('Inbox:noEdit/From the Emperor/Your mission', {'cmd':'msg', 'msg':"res://data/conv/emperor_your_mission.txt"})
	officeOrg.add_entry('Inbox:noEdit/History/On Sacred Science', {'cmd':'msg', 'msg':"""
- 
"""})
	GameState.add_organizer('office', officeOrg)
	UI.rightOrganizer.refresh_organizer_data(GameState.get_organizer_data('office'))
	UI.rightOrganizer.visible = true
	UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder').set_no_drag(true)
	UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder').set_no_delete(true)
	yield(get_tree(), 'idle_frame')
	

func tutorial_first_decree():
	UI.rightOrganizer.visible = true
	UI.controlsContainer.visible = false
	UI.timePassContainer.visible = false
	var c = Conversation
	c.clear()
	c.speaking('helper')
	c.text("""
{playerName}, please review the workorder in your outbox and make any changes as you see fit!
""")
	var workorder = UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder')
	workorder.call_attention()
	UI.call_attention_from_left(workorder)
	workorder.connect('entry_clicked', self, 'first_decree_clicked')
	c.run()

func first_decree_clicked():
	var c = Conversation
	var workorder = UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder')
	workorder.disconnect('entry_clicked', self, 'first_decree_clicked')
	UI.lastPopup.connect('popup_hide', self, 'first_decree_closed')
	c.clear()
	c.speaking('helper')
	c.text("""
You might increase the gift we send along with the decree if you would like to reduce any resentment the locals may feel at your decree, but please keep in mind that our funds are limited - going into debt will more than offset any goodwill we might gain with lavish gifts now!
""")
	yield(c.run(), 'completed')
	
func first_decree_closed():
	GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_DISCARD_RUBBISH
	setup_quest()

func create_rubbish():
	return UI.rightOrganizer.add_new_entry('Discarded decrees', {'cmd':'msg', 'msg':"Greetings, peasants! Your labor is required by the Emperor! ...no, that's terrible.\n\nBehold the words of the Emperor's duly appointed... hm.\n\nSalutations, dear villagers. If it isn't too much trouble, would you consider reporting to...arrrgh!"}, 'tutorial_rubbish')

func tutorial_discard_rubbish():
	var existingRubbish = UI.rightOrganizer.get_entry_by_id('tutorial_rubbish')
	if !existingRubbish: existingRubbish = create_rubbish()
	UI.controlsContainer.visible = false
	UI.timePassContainer.visible = false
	var c = Conversation
	c.clear()
	c.speaking('helper')
	c.text("""
Ah! Forgive my mess {playerName}, these are decree drafts that should be discarded! 
Please feel free to drag those into the garbage bin where they belong! 
""")
	existingRubbish.call_attention()
	UI.call_attention_from_left(existingRubbish)
	existingRubbish.connect('entry_deleted', self, 'rubbish_deleted')
	c.run()
	
func rubbish_deleted():
	GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_PASS_TIME
	setup_quest()

func tutorial_pass_time():
	UI.controlsContainer.visible = false
	UI.timePassContainer.visible = true
	var c = Conversation
	c.clear()
	c.speaking('helper')
	c.page("""
That was a good start, but I'm afraid we have at least another week of cleanup ahead of us...it will take that long for any response from the villagers, anyway.
Well, no sense in waiting - let's get started!
""")
	c.clear()
	c.text("Remember, although you are of course free to organize your documents as you see fit, you must leave any decrees you want processed in your Outbox before the end of the day!")
	yield(c.run(), 'completed')
	UI.call_attention_from_left(UI.timePassContainer)
