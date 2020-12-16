extends Node

signal chakraZoom(amt) # (amt)

signal organizer_entry_clicked(organizer, organizerEntryClicked) # (organizer, organizer_entry_clicked)
signal organizer_entry_toggled(organizer, organizerEntryToggled, isTurnedOn) # (organizer, organizer_entry_toggled, isTurnedOn)

signal set_mouse_image(mouseImageNodeName)
signal show_query_popup(query_popup, query_popup_target)

signal load_scene
signal new_scene_loaded(newScene)

signal show_character(characterImgPath) # load the specified image and show it on the UI
signal hide_character # () - hide any shown characters

var textInterface:TextInterface

func write_text_with_breaks(text_to_write):
	var chunks = text_to_write.trim_prefix('\n').split('\n\n')
	var firstChunk = true
	for chunk in chunks:
		if !firstChunk: 
			textInterface.buff_break()
			textInterface.buff_clear()
		textInterface.buff_text(chunk.format(GameState.settings))
		firstChunk = false
		
func wait_for_text():
	yield(textInterface, 'buff_end')

func show_character(characterImg):
	if !characterImg.begins_with('res:'):
		characterImg = 'res://img/people/%s.png'%characterImg
	emit_signal('show_character', characterImg)
	
func hide_character():
	emit_signal('hide_character')

func clear_text():
	textInterface.clear_text()

func _on_Event_organizer_entry_clicked(organizer, organizerEntryClicked:OrganizerEntry):
	if organizerEntryClicked && organizerEntryClicked.data && organizerEntryClicked.data['cmd']:
		GameState.run_command(organizerEntryClicked.data['cmd'], organizerEntryClicked.data, organizerEntryClicked)

