extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()

# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

# Check for any important quest states and setup as needed, may call setup_default() manually as well if needed
func setup_quest():
	if GameState.quest.get('placeholder') > 0:
		return true # Make any changes you need here...
	return .setup_quest()
