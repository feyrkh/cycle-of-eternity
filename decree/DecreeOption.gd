extends OptionButton
class_name DecreeOption

var id

signal option_changed(id, optionData)

func _on_OptionButton_item_selected(index):
	emit_signal('option_changed', id, index)
