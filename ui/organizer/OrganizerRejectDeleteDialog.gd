extends AcceptDialog
class_name OrganizerDeleteRejectDialog


func _on_OrganizerRejectDeleteDialog_popup_hide():
	queue_free()


func _on_OrganizerRejectDeleteDialog_about_to_show():
	var mousePos = get_global_mouse_position()
	rect_position = mousePos - rect_size / 2
