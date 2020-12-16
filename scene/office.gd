extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()

# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

# Check for any important quest states and setup as needed, may call setup_default() manually as well if needed
func setup_quest():
	if GameState.quest.get(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_OFFICE:
		Event.show_character('secretary')
		Event.write_text_with_breaks("""
Welcome to your office for the first time!
""")
		yield(Event.wait_for_text(), 'completed')
		GameState.quest[Quest.Q_TUTORIAL] = null
		return true # Make any changes you need here...
	return .setup_quest()
