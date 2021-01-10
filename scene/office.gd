extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()
	UI.load_right_organizer('office')
	Event.connect("pass_time", self, "on_pass_time")
	Event.connect("finalize_place_item", self, "on_finalize_place_item")
	Event.connect("place_item", self, "on_place_item")
	Event.connect("cancel_place_item", self, "on_cancel_place_item")

# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

# Check for any important quest states and setup as needed, if this returns true then set_default() will be skipped; may call setup_default() manually as well if needed
func setup_quest()->bool:
	match GameState.get_quest_status(Quest.Q_TUTORIAL):
		Quest.Q_TUTORIAL_OFFICE: 
			tutorial_office_intro()
			return true
		Quest.Q_TUTORIAL_PLACE_DESK: 
			tutorial_place_desk()
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
		Quest.Q_TUTORIAL_BUILD_TRAINING:
			tutorial_build_training_hall()
			return true
		Quest.Q_TUTORIAL_WAIT_FOR_TRAINING_HALL:
			tutorial_wait_training_hall()
			return true
		Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
			tutorial_install_equipment()
			return true
	return false


func on_pass_time(timeAmt):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_PASS_TIME:
		Conversation.clear()
		Conversation.run()
		var workorder = GameState._organizers['office'].get_entry_by_id('tutorialFirstWorkOrder')
		if !workorder or workorder.get('data').projectComplete: # player passed time and the workorder is completed, now we should have at least one work crew; now we need to create a training hall
			GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_BUILD_TRAINING)
			setup_construction_decrees()
			setup_quest()
	elif GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_BUILD_TRAINING or GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_WAIT_FOR_TRAINING_HALL:
		if GameState.settings.get('id_trainingHall', 0) >= 1: 
			GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_INSTALL_EQUIPMENT)
			#setup_disciple_decrees()
			setup_quest()
		else: 
			tutorial_wait_training_hall()

func on_place_item(itemShadow, itemData, sourceNode):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_PLACE_DESK: # must have placed the desk, time for the first decree
		Conversation.clear()
		Conversation.speaking(null)
		Conversation.text("Placing items: resize with mouse wheel, flip with middle mouse button, cancel with right-click, confirm placement with left-click.")
		Conversation.run()


func on_finalize_place_item(position, scale, rotation, itemData, sourceNode):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_PLACE_DESK: # must have placed the desk, time for the first decree
		Conversation.clear()
		Conversation.run()
		setup_first_decree()

func on_cancel_place_item():
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_PLACE_DESK: # must have placed the desk, time for the first decree
		Conversation.clear()
		Conversation.run()


func tutorial_office_intro():
	UI.leftOrganizer.visible = true
	UI.rightOrganizer.visible = false
	UI.controlsContainer.visible = false
	UI.timePassContainer.visible = false

	var officeOrg = load("res://ui/organizer/OrganizerData.gd").new()
	officeOrg.add_folder('Outbox^noEdit^isOpen^noDelete', 'outbox')
	officeOrg.add_folder('Inbox^noEdit', 'inbox')
	officeOrg.add_folder('Furniture^isOpen', 'furniture')
	officeOrg.add_entry("{playerName}'s desk^noDelete^isUnread".format(GameState.settings), 'res://data/producer/office_desk.json', 'office_desk', 'furniture')
	GameState.add_organizer('office', officeOrg)
	UI.rightOrganizer.refresh_organizer_data(GameState.get_organizer_data('office'))
	UI.rightOrganizer.visible = true
	yield(get_tree(), "idle_frame")
	GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_PLACE_DESK)
	setup_quest()

func tutorial_place_desk():
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_PLACE_DESK:
		UI.leftOrganizer.visible = true
		UI.rightOrganizer.visible = true
		UI.controlsContainer.visible = false
		UI.timePassContainer.visible = false
		var c = Conversation
		c.speaking('helper')
		c.text("""
This will be your office, {playerName}. From here you will administer the new school of the sacred science - making personnel decisions, reviewing resource allocations, sending decrees, and receiving updates from your subordinates.

If you take a look to your right, I've procured a desk for your paperwork. If you'll just point out where you would like it, I will see to it immediately!
""")
		yield(c.run(), 'completed')
		c.speaking(null)
		c.run()
		UI.call_attention_right_organizer('office_desk')

func setup_first_decree():
	var decreeData = load("res://decree/DecreeData.gd").new()
	decreeData.init_from_file("res://data/decree/hireWorkCrew.json")
	var officeOrg = GameState.get_organizer_data('office')
	officeOrg.add_entry('Raise Work Crew^isUnread', decreeData, 'tutorialFirstWorkOrder', 'outbox')
	officeOrg.add_entry('From the Emperor/Your mission^isUnread', {'cmd':'msg', 'msg':"res://data/conv/emperor_your_mission.txt"}, null, 'inbox')
	officeOrg.add_entry('Library/History of the Shadow Aegis^isUnread', {'cmd':'msg', 'msg':'res://data/conv/shadow_aegis.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/On Souls^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_1.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/On Essence^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_2.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/Exemplars^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_3.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/Condensing Essence^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_4.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/Storing Aura^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_5.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/Using Aura^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_6.txt'}, null, 'inbox')
	officeOrg.add_entry('Library/Sacred Science/Advancement^isUnread', {'cmd':'msg', 'msg':'res://data/conv/sacred_science_7.txt'}, null, 'inbox')
	UI.rightOrganizer.refresh_organizer_data(GameState.get_organizer_data('office'))
	UI.rightOrganizer.visible = true
	UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder').set_no_drag(true)
	UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder').set_no_delete(true)
	yield(get_tree(), 'idle_frame')
	GameState.set_quest_status(Quest.Q_TUTORIAL,  Quest.Q_TUTORIAL_FIRST_DECREE)
	setup_quest()
	

func tutorial_first_decree():
	UI.leftOrganizer.visible = true
	UI.rightOrganizer.visible = true
	UI.controlsContainer.visible = false
	UI.timePassContainer.visible = false
	var c = Conversation
	c.clear()
	c.speaking('helper')
	c.text("""
I have taken the liberty of drawing up your first decree - the drafting of a work party from the nearby villages. With these workers we can get started on the infrastructure we need to support our studies into the sacred arts.

{playerName}, please review the workorder in your outbox and make any changes as you see fit! Any decrees in your outbox at the end of the week will be carried out!
""")
	yield(c.run(), "completed")
	var workorder = UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder')
	UI.call_attention_from_left(workorder)
	workorder.connect('entry_clicked', self, 'first_decree_clicked')

func first_decree_clicked():
	var c = Conversation
	var workorder = UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder')
	workorder.disconnect('entry_clicked', self, 'first_decree_clicked')
	if UI.lastPopup: UI.lastPopup.connect('popup_hide', self, 'first_decree_closed')
	c.clear()
	c.speaking('helper')
	c.text("""
You might increase the gift we send along with the decree if you would like to reduce any resentment the locals may feel at your decree, but please keep in mind that our funds are limited - going into debt will more than offset any goodwill we might gain with lavish gifts now!
""")
	yield(c.run(), 'completed')
	
func first_decree_closed():
	GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_DISCARD_RUBBISH)
	setup_quest()

func create_rubbish():
	return UI.rightOrganizer.add_new_entry('Discarded decrees', {'cmd':'msg', 'msg':"Greetings, peasants! Your labor is required by the Emperor! ...no, that's terrible.\n\nBehold the words of the Emperor's duly appointed... hm.\n\nSalutations, dear villagers. If it isn't too much trouble, would you consider reporting to...arrrgh!"}, 'tutorial_rubbish', 
		Util.build_entry_flags(['isUnread']))

func tutorial_discard_rubbish():
	var existingRubbish = UI.rightOrganizer.get_entry_by_id('tutorial_rubbish')
	if !existingRubbish: existingRubbish = create_rubbish()
	UI.leftOrganizer.visible = true
	UI.rightOrganizer.visible = true
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
	var trashIcon = UI.rightOrganizer.find_node('DeleteTarget', true, false)
	if trashIcon:
		UI.call_attention_from_left(trashIcon)
	existingRubbish.connect('entry_deleted', self, 'rubbish_deleted')
	c.run()
	
func rubbish_deleted():
	GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_PASS_TIME)
	setup_quest()

func tutorial_pass_time():
	UI.leftOrganizer.visible = true
	UI.rightOrganizer.visible = true
	UI.timePassContainer.visible = true
	UI.controlsContainer.visible = true
	var c = Conversation
	c.clear()
	c.speaking('helper')
	c.page("""
That was a good start, but I'm afraid we have at least another few days of cleanup ahead of us...it will take that long for any response from the villagers, anyway.
Well, no sense in waiting - let's get started!
""")
	c.clear()
	c.text("Remember, although you are of course free to organize your documents as you see fit, you must leave any decrees you want processed in your Outbox before the end of the day!")
	yield(c.run(), 'completed')
	GameState.settings['allowTimePass'] = true
	UI.call_attention_from_left(UI.timePassContainer)

func setup_construction_decrees():
	var org = GameState._organizers['main']
	org.add_folder('Decrees^noDelete^isOpen', 'decreeGen')
	var decreeGen = {'cmd':'decreeGen', 'decreeFile':"res://data/decree/buildTrainingHall.json", 'org':'office', 'folderId':'outbox', 'gotoScene':'office'}
	org.add_entry('Build training hall^isUnread^noEdit^noDelete', decreeGen, 'decree_buildTrainingHall', 'decreeGen')
	decreeGen = {'cmd':'decreeGen', 'decreeFile':"res://data/decree/hireWorkCrew.json", 'org':'office', 'folderId':'outbox', 'gotoScene':'office'}
	org.add_entry('Hire work crew^noEdit^noDelete', decreeGen, 'decree_hireWorkCrew', 'decreeGen')
	GameState.refresh_organizers()

func tutorial_build_training_hall():
	UI.leftOrganizer.visible = true
	UI.rightOrganizer.visible = true
	UI.timePassContainer.visible = true
	UI.controlsContainer.visible = true
	var c = Conversation
	c.clear()
	c.speaking('helper')
	UI.call_attention_from_right(UI.leftOrganizer.get_entry_by_id('new'))
	c.page("""
Now that you have some workers we can begin construction of a training hall. When that is finished we'll be able to start a training regimen.
While I hope you find me worthy to be the first sacred scientist to start their training, you may also search for other candidates if you wish. I will return when the training hall is complete.""")
	c.clear()
	c.speaking(null)
	yield(c.run(), "completed")
	UI.call_attention_left_organizer('decree_buildTrainingHall')
	GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_WAIT_FOR_TRAINING_HALL)

func tutorial_wait_training_hall():
	var decrees = GameState._organizers['office'].get_entries_with_type('project')
	var trainingHall = GameState._organizers['main'].get_entry_by_id('trainingHall1')
	if decrees.size() != 0 or trainingHall == null:
		return
	Conversation.clear()
	Conversation.text("Reminder: Decree the construction of a training hall, and pass time until it is completed.")
	Conversation.run()



func tutorial_install_equipment():
	Conversation.clear()
	Conversation.speaking('helper')
	Conversation.text("Oh good, it's finished! It's a little...small.\nBut no matter, I'm sure it will do for now! I will meet you there.")
	Conversation.run()
	
	
