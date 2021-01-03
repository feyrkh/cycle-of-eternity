extends ConfirmationDialog

var sparCmdData
var exemplarData

func _ready():
	if get_parent() == get_tree().root: popup_centered()
	get_ok().disabled = true

func _on_ExemplarSelector_exemplar_selected(exemplarData):
	get_ok().disabled = exemplarData == null
	self.exemplarData = exemplarData


func _on_SparStartPrompt_confirmed():
	#Event.special_event(exemplarData.entityName+" started sparring: "+to_json(sparCmdData), "spar")
	var combatData = {
		"combatType": "spar",
		"exemplarData": [
			exemplarData
		],
		"opponentData": sparCmdData.get('opponent')
	}
	GameState.run_command('combat', combatData, self)
