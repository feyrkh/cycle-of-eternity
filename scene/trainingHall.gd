extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()
	if GameState.settings.get('sparringUnlocked', false):
		setup_sparring()
	Event.connect("pass_time", self, "on_pass_time")
	Event.connect("organizer_entry_clicked", self, "on_organizer_entry_clicked")
	Event.connect("place_item", self, "on_place_item")
	Event.connect("finalize_place_item", self, "on_finalize_place_item")
	Event.connect("training_added", self, "on_training_added")
	
# Check for any important quest states and setup as needed, if this returns true then set_default() will be skipped; may call setup_default() manually as well if needed
func setup_quest()->bool:
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
		Conversation.clear()
		Conversation.speaking('helper')
		Conversation.text("Before any training can occur, you must order the installation of training equipment - just like you installed your office desk!")
		Conversation.run()
		return true
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_OBTAIN_DISCIPLE:
		GameState.add_resource("disciple", 1, null, {
			"name": GameState.settings.get('helperName'),
			"id": "helper",
			"rigor": 4,
			"gender": "f",
		})
		GameState.refresh_organizers()
		var item = UI.leftOrganizer.get_entry_by_id('helper')
		UI.call_attention_from_right(item)
		GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_TRAIN_DISCIPLE)
		setup_quest()
		return true
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_TRAIN_DISCIPLE:
		Conversation.clear()
		Conversation.speaking('helper')
		Conversation.text("Now to set up a training program! To get started, just open up my personnel file - it should be in your New Arrivals folder, but please feel free to reorganize as you like. Oh - my name is {helperName}, by the way!")
		Conversation.run()
		setup_disciple_decrees()
		UI.call_attention_left_organizer('new')
		return true
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_SPAR_ATTACK:
		Conversation.clear()
		Conversation.speaking('helper')
		Conversation.page("Training takes a long time to show results, especially if you're already near the limits of your ability, but I believe that the sacred science will allow us to transcend those limits into unimaginable realms of power!\nLet's try out our new training hall by attacking a wooden dummy.")
		Conversation.run()
		UI.call_attention_right_organizer('sparAttackDummy')
	return false

func on_pass_time(timeAmt):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_TRAIN_DISCIPLE:
		pass

func on_organizer_entry_clicked(organizer, organizerEntryClicked):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_TRAIN_DISCIPLE:
		if organizerEntryClicked and organizerEntryClicked.id == 'helper':
			Conversation.clear()
			Conversation.page("Here you can adjust my training plan. Training in different locations and with different equipment available may lead to better outcomes, while progress will slow as I approach my physical limits.\nPlease queue up at least one exercise!")
			Conversation.run()
			GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_QUEUE_TRAINING)
			

func on_place_item(itemShadow, itemData, sourceNode):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
		Conversation.clear()
		Conversation.speaking(null)
		Conversation.text("Placing items: resize with mouse wheel, flip with middle mouse button, cancel with right-click, confirm placement with left-click.")
		Conversation.run()


func on_finalize_place_item(position, scale, rotation, itemData, sourceNode):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
		Conversation.clear()
		Conversation.run()
		GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_OBTAIN_DISCIPLE)
		setup_quest()

func setup_disciple_decrees():
	var org = GameState._organizers['main']
	if !org.get_entry_by_id('decree_hireDisciple'):
		var decreeGen = {'cmd':'decreeGen', 'decreeFile':"res://data/decree/hireDisciple.json", 'org':'office', 'folderId':'outbox', 'gotoScene':'office'}
		org.add_entry('Seek disciples^noEdit^noDelete', decreeGen, 'decree_hireDisciple', 'decreeGen')
		GameState.refresh_organizers()

func on_training_added(exemplarData, trainingData, count, repeat, entryName):
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_QUEUE_TRAINING:
		GameState.settings['sparringUnlocked'] = true
		GameState.settings['sparAttackUnlock'] = true
		GameState.save_organizers()
		setup_sparring()
		GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_SPAR_ATTACK)
		setup_quest()
		
func setup_sparring():
	var updateMade = false
	if GameState.settings.get('sparAttackUnlock') and !rightOrganizerData.get_entry_by_id('sparAttackDummy'):
		updateMade = true
		rightOrganizerData.add_entry("Attack dummy^noDelete^isUnread", {'cmd':'placeable',  "img":"res://img/items/attack_dummy.png", 'placedCmd':'spar', 'opponent':'res://data/opponent/attackDummy.json'}, 'sparAttackDummy', 'equipment')
	if GameState.settings.get('sparDefenseUnlock') and !rightOrganizerData.get_entry_by_id('sparDefenseDummy'):
		updateMade = true
		rightOrganizerData.add_entry("Defense dummy^noDelete^isUnread", {'cmd':'placeable',  "img":"res://img/items/defense_dummy.png", 'placedCmd':'spar', 'opponent':'res://data/opponent/defenseDummy.json'}, 'sparDefenseDummy', 'equipment')
	
	if updateMade:
		UI.rightOrganizer.refresh_organizer_data(rightOrganizerData)
		UI.rightOrganizer.save()
	
