extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()
	Event.connect("pass_time", self, "on_pass_time")
	Event.connect("organizer_entry_clicked", self, "on_organizer_entry_clicked")
	Event.connect("place_item", self, "on_place_item")
	Event.connect("finalize_place_item", self, "on_finalize_place_item")
	
# Check for any important quest states and setup as needed, if this returns true then set_default() will be skipped; may call setup_default() manually as well if needed
func setup_quest()->bool:
	if GameState.quest[Quest.Q_TUTORIAL] == Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
		Conversation.clear()
		Conversation.speaking('helper')
		Conversation.text("Before any training can occur, you must order the installation of training equipment - just like you installed your office desk!")
		Conversation.run()
		return true
	if GameState.quest[Quest.Q_TUTORIAL] == Quest.Q_TUTORIAL_OBTAIN_DISCIPLE:
		GameState.add_resource("disciple", 1, null, {
			"name": GameState.settings.get('helperName'),
			"id": "helper",
			"rigor": 4,
			"gender": "f",
		})
		GameState.refresh_organizers()
		var item = UI.leftOrganizer.get_entry_by_id('helper')
		UI.call_attention_from_right(item)
		GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_TRAIN_DISCIPLE
		setup_quest()
		return true
	if GameState.quest[Quest.Q_TUTORIAL] == Quest.Q_TUTORIAL_TRAIN_DISCIPLE:
		Conversation.clear()
		Conversation.speaking('helper')
		Conversation.text("Now to set up a training program! To get started, just open up my personnel file - it should be in your New Arrivals folder, but please feel free to reorganize as you like. Oh - my name is {helperName}, by the way!")
		Conversation.run()
		setup_disciple_decrees()
		return true
	return false

func on_pass_time(timeAmt):
	if GameState.quest[Quest.Q_TUTORIAL] == Quest.Q_TUTORIAL_TRAIN_DISCIPLE:
		pass

func on_organizer_entry_clicked(organizer, organizerEntryClicked):
	if GameState.quest[Quest.Q_TUTORIAL] == Quest.Q_TUTORIAL_TRAIN_DISCIPLE:
		if organizerEntryClicked and organizerEntryClicked.id == 'helper':
			Conversation.clear()
			Conversation.page("Here you can adjust my training plan. Training in different locations and with different equipment available may lead to better outcomes, while progress will slow as I approach my physical limits.\nPlease queue up at least one exercise!")
			Conversation.run()
			GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_QUEUE_TRAINING
			

func on_place_item(itemShadow, itemData, sourceNode):
	if GameState.quest.get(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
		Conversation.clear()
		Conversation.speaking(null)
		Conversation.text("Placing items: resize with mouse wheel, flip with middle mouse button, cancel with right-click, confirm placement with left-click.")
		Conversation.run()


func on_finalize_place_item(position, scale, rotation, itemData, sourceNode):
	if GameState.quest.get(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_INSTALL_EQUIPMENT:
		Conversation.clear()
		Conversation.run()
		GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_OBTAIN_DISCIPLE
		setup_quest()

func setup_disciple_decrees():
	var org = GameState._organizers['main']
	if !org.get_entry_by_id('decree_hireDisciple'):
		var decreeGen = {'cmd':'decreeGen', 'decreeFile':"res://data/decree/hireDisciple.json", 'org':'office', 'folderId':'outbox', 'gotoScene':'office'}
		org.add_entry('Seek disciples^noEdit^noDelete', decreeGen, 'decree_hireDisciple', 'decreeGen')
		GameState.refresh_organizers()
