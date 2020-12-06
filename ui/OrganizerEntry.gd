extends PanelContainer
class_name OrganizerEntry

export var labelText = 'entry'

func _ready():
	print('loading')
	$HBoxContainer/Label.text = labelText
	labelText = null
