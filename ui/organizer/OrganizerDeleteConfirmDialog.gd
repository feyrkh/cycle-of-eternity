extends ConfirmationDialog
class_name OrganizerDeleteConfirmationDialog

func _on_OrganizerDeleteConfirmDialog_popup_hide():
	queue_free()


func _on_OrganizerDeleteConfirmDialog_about_to_show():
	var mousePos = get_global_mouse_position()
	rect_position = mousePos - rect_size / 2
