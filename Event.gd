extends Node

signal save_state_loaded

signal chakraZoom(amt) # (amt)

signal organizer_entry_clicked(organizer, organizerEntryClicked) # (organizer, organizer_entry_clicked)
signal organizer_entry_toggled(organizer, organizerEntryToggled, isTurnedOn) # (organizer, organizer_entry_toggled, isTurnedOn)

signal set_mouse_image(mouseImageNodeName)
signal show_query_popup(query_popup, query_popup_target)

signal load_scene
signal new_scene_loaded(newScene)

signal show_character(characterImgPath) # load the specified image and show it on the UI
signal hide_character # () - hide any shown characters
signal msg_popup(msg, sourceNode) # pop up a scrollable text message

signal before_pass_time()
signal pass_time(amt)
signal after_pass_time()
signal after_calendar_update(newDate)
signal time_should_pause()
signal pause_key_mutex(amt) # call with amt=1 when doing something that might require pressing the spacebar, which is used for pausing/unpausing the flow of time, and with -1 when that thing is finished.
signal special_event(msgData, category)

signal place_item(itemShadow, itemData, sourceNode) # place an item into a location
signal cancel_place_item() # cancelled placement of an item
signal finalize_place_item(position, scale, rotation, itemData, sourceNode)
signal restore_item_placement(itemData, hover) # on reloading a scene, add a previously placed item back into the correct layer
signal clear_item_placement()

signal open_char_status()
signal close_char_status()
signal training_queues_updated()
signal training_added(exemplarData, trainingData, count, repeat, entryName)

signal entering_combat(combatScene)
signal leaving_combat(combatScene)
signal update_target_lines()
signal combat_speed_multiplier(multiplier) # how fast combat animation should occur
signal exemplar_combatant_selected(combatant)
signal opponent_combatant_selected(combatant)

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
	textInterface.reset()

func special_event(msgData, category):
	emit_signal("special_event", msgData, category)

func _on_Event_organizer_entry_clicked(organizer, organizerEntryClicked:OrganizerEntry):
	if organizer.ignoreEntryClicks: return
	if !organizerEntryClicked || !organizerEntryClicked.data: 
		printerr('No data for clicked organizer entry: ', organizerEntryClicked)
		return
	if organizerEntryClicked.data is Dictionary and organizerEntryClicked.data.has('cmd'):
		GameState.run_command(organizerEntryClicked.data['cmd'], organizerEntryClicked.data, organizerEntryClicked)
	elif !(organizerEntryClicked.data is Dictionary) and organizerEntryClicked.data.has_method('on_organizer_entry_clicked'):
		organizerEntryClicked.data.on_organizer_entry_clicked(organizerEntryClicked)
	else: 
		printerr("Don't know what to do with organizerEntry data that doesn't have 'cmd' or 'on_organizer_entry_clicked'")
