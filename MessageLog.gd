extends Control

const MSG_TRAINING_PROBLEM = 'training_problem'
const MSG_DECREE_COMPLETE = 'decree_complete'

func ready():
	Event.connect("save_state_loaded", self, "on_save_state_loaded")
	Event.connect("special_event", self, "on_special_event")

func clear(): 
	var msgLog = get_tree().root.find_node("MessageLogDisplay", true, false)
	if msgLog: msgLog.text = ""

func on_save_state_loaded():
	clear()
