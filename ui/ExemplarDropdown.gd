extends OptionButton

var exemplarDataList = []

signal exemplar_selected(exemplarData)

func _ready():
	self.add_item('-- Select combatant --')
	var exemplarEntries = GameState.get_organizer_data('main').get_entries_with_type('exemplar')
	for exemplarEntry in exemplarEntries:
		var exemplarData = exemplarEntry.data
		exemplarDataList.append(exemplarData)
		self.add_item(exemplarData.entityName)


func _on_ExemplarSelector_item_selected(index):
	var exemplarData
	if index == 0:
		exemplarData = null
	else:
		exemplarData = exemplarDataList[index-1]
	emit_signal('exemplar_selected', exemplarData)
