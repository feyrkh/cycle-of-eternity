extends Node2D

onready var leftOrganizer:Organizer = find_node('Organizer')
onready var rightOrganizer:Organizer = find_node('Organizer2')
onready var charOrganizer:Organizer = find_node('CharOrganizer')
onready var textInterfaceSplit:VSplitContainer = find_node('VSplitContainer')
onready var timePassContainer = find_node('TimePassContainer')
onready var timePassButton = find_node('TimePassButton')
onready var controlsContainer = find_node('ControlsContainer')
onready var dragSurface = find_node('DragSurface')

var folderScene = load('res://ui/organizer/OrganizerFolder.tscn')
var entryScene = load('res://ui/organizer/OrganizerEntry.tscn')
var msgPopupScene = load('res://ui/MsgPopup.tscn')
var textInterface

var lastPopup

func _ready():
	textInterface = $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/TIE
	Event.textInterface = textInterface
#	Conversation.connect("conversation_started", leftOrganizer, 'disable')
#	Conversation.connect("conversation_started", rightOrganizer, 'disable')
#	Conversation.connect("conversation_ended", leftOrganizer, 'reenable')
#	Conversation.connect("conversation_ended", rightOrganizer, 'reenable')
#	Event.textInterface.connect('state_change', leftOrganizer, 'disable_on_conversation')
#	Event.textInterface.connect('state_change', rightOrganizer, 'disable_on_conversation')
#	Event.textInterface.connect('state_change', timePassButton, 'disable_on_conversation')
#	Event.textInterface.connect('buff_end', leftOrganizer, 'reenable')
#	Event.textInterface.connect('buff_end', rightOrganizer, 'reenable')
#	Event.textInterface.connect('buff_end', timePassButton, 'reenable')
#	Event.textInterface.connect('buff_cleared', leftOrganizer, 'reenable')
#	Event.textInterface.connect('buff_cleared', rightOrganizer, 'reenable')
#	Event.textInterface.connect('buff_cleared', timePassButton, 'reenable')
	Event.connect("show_character", self, 'on_show_character')
	Event.connect("hide_character", self, 'on_hide_character')
	Event.connect("msg_popup", self, 'on_msg_popup')
	Event.connect('new_scene_loaded', self, 'on_new_scene_loaded')
	Event.connect("pass_time", self, 'on_pass_time')
	Event.connect('place_item', self, 'on_place_item')

	_on_DragSurface_resized()
	_on_TextBoxContainer_resized()
	GameState.UI = self
	var leftOrganizerName = GameState.settings.get('leftOrganizerName')
	var rightOrganizerName = GameState.settings.get('rightOrganizerName')
	if leftOrganizerName: load_left_organizer(leftOrganizerName)
	if rightOrganizerName: load_right_organizer(rightOrganizerName)

func on_pass_time(timeAmt:int):
	pass

func on_show_character(charImgPath):
	$CanvasLayer/Character.visible = true
	$CanvasLayer/Character.texture = load(charImgPath)
	
func on_hide_character():
	$CanvasLayer/Character.visible = false

func on_new_scene_loaded(newScene):
	pass

func _on_TextBoxContainer_resized():
	$CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/Blinker.position = $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer.rect_size - Vector2(0, $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer.rect_size.y) - $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/Blinker.get_rect().size - Vector2(10,10)

func _on_DragSurface_resized():
	$CanvasLayer/Character.rect_global_position = $CanvasLayer/HBoxContainer/VSplitContainer/DragSurface.rect_global_position
	$CanvasLayer/Character.rect_size = $CanvasLayer/HBoxContainer/VSplitContainer/DragSurface.rect_size

func add_inner_panel_popup(item):
	if item.get_parent(): item.get_parent().remove_child(item)
	dragSurface.add_child(item)
	lastPopup = item

func clear_inner_panel():
	for child in dragSurface.get_children():
		if child.has_method('on_close'): child.on_close()
		child.queue_free()
		dragSurface.remove_child(child)

func add_popup(item):
	if item.get_parent(): item.get_parent().remove_child(item)
	$PopupLayer.add_child(item)
	lastPopup = item

func on_msg_popup(data, sourceNode):
	var msg
	if data is Dictionary: msg = data.get('msg')
	else: msg = data
	if !msg: 
		printerr('Empty message in on_msg_popup')
		return
	if msg.begins_with('res:'): 
		msg = Util.load_text_file(msg)
		if !msg: msg = '(missing file: %s)'%data.get('msg')
	var popup = msgPopupScene.instance()
	add_popup(popup)
	popup.set_text(msg)
	if data.get('img'): popup.set_image(data.get('img'))
	popup.popup()
	#popup.popup_centered(OS.get_window_size()/3*2)

func load_right_organizer(organizerName, skipSave=false):
	load_organizer(organizerName, rightOrganizer, skipSave)
	GameState.settings['rightOrganizerName'] = organizerName

func load_left_organizer(organizerName, skipSave=false):
	load_organizer(organizerName, leftOrganizer, skipSave)
	GameState.settings['leftOrganizerName'] = organizerName

func load_char_organizer(organizerName, skipSave=false):
	load_organizer(organizerName, charOrganizer, skipSave)

func load_organizer(organizerName, organizer, skipSave=false):
	if !skipSave:
		organizer.save()
	var organizerData = GameState.get_organizer_data(organizerName)
	if !organizerData:
		organizerData = OrganizerData.new()
		organizerData.name = organizerName
		GameState.add_organizer(organizerName, organizerData)
	if organizerData:
		organizer.refresh_organizer_data(organizerData)

func save_organizers():
	if leftOrganizer.organizerDataName:
		leftOrganizer.save()
	if rightOrganizer.organizerDataName:
		rightOrganizer.save()
	if charOrganizer.visible and charOrganizer.organizerDataName:
		charOrganizer.save()
	
func clear_organizer():
	rightOrganizer.clear()

func _on_TIE_gui_input(event):
	if event is InputEventMouseButton:
		var e = event as InputEventMouseButton
		print('clicked! ', e.pressed, '; ', e.button_index)
		if e.pressed and e.button_index == 1:
			textInterface.resume_break()
			
func serialize_text_interface()->String:
	var s = {}
	s['splitContainerOffset'] = textInterfaceSplit.split_offset
	return s
	

func deserialize_text_interface(serializedTextInterface):
	if !serializedTextInterface: return
	var s = serializedTextInterface
	textInterfaceSplit.split_offset = s['splitContainerOffset']
	textInterface.reset()
#	textInterface.refresh_settings(s)

func call_attention_left_organizer(entryId:String):
	var target = leftOrganizer.get_entry_by_id(entryId)
	if target: 
		if target.has_method('pulse_until_clicked'):
			target.pulse_until_clicked()
		call_attention_from_right(target)

func call_attention_right_organizer(entryId:String):
	var target = rightOrganizer.get_entry_by_id(entryId)
	if target: 
		if target.has_method('pulse_until_clicked'):
			target.pulse_until_clicked()
		call_attention_from_left(target)

func call_attention_from_left(target:Control):
	var pointer = load("res://ui/CallAttention.tscn").instance()
	pointer.target = target
	add_popup(pointer)
	pointer.call_attention_from_left(target)

func call_attention_from_right(target:Control):
	var pointer = load("res://ui/CallAttention.tscn").instance()
	pointer.target = target
	add_popup(pointer)
	pointer.call_attention_from_right(target)

func on_place_item(itemShadow, itemData, sourceNode):
	clear_inner_panel()

func reset_camera():
	$Camera2D.offset = Vector2.ZERO
	$Camera2D.position =  OS.window_size/2
	$Camera2D.zoom = Vector2.ONE

func enter_combat_mode():
	leftOrganizer.visible = false
	charOrganizer.visible = false
	textInterface.visible = false
	timePassContainer.visible = false
	dragSurface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	find_node("DateLabel").visible = false
	#find_node("DateProgressBar").visible = false

func leave_combat_mode():
	leftOrganizer.visible = true
	textInterface.visible = true
	timePassContainer.visible = true
	dragSurface.mouse_filter = Control.MOUSE_FILTER_PASS
	find_node("DateLabel").visible = true
	find_node("DateProgressBar").visible = true
	
