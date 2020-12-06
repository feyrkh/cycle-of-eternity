extends ColorRect
class_name DragHandle

signal on_drag_started # (self)

#func _on_DragHandle_gui_input(event):
#	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT and event.pressed:
#			emit_signal("on_drag_started", self)

func get_drag_data(pos):
	print('dragging ', self, ' from ', pos)
	var preview = ColorRect.new()
	preview.color = Color.yellow
	set_drag_preview(preview)
	return self
	
func can_drop_data(pos, data):
	return true
	
func drop_data(pos, data):
	pass
