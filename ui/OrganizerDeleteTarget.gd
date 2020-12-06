extends TextureRect

func can_drop_data(position, data):
	var retval = (data is OrganizerEntry) or (data is OrganizerFolder)
	if retval: 
		self.modulate = Color.pink
	return retval
	
func drop_data(position, data):
	if data.has_method('ask_to_delete'): data.ask_to_delete()

func _on_DeleteTarget_mouse_exited():
	self.modulate = Color.white
