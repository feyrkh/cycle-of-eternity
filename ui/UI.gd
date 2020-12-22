extends Node2D

onready var leftOrganizer:Organizer = find_node('Organizer')
onready var rightOrganizer:Organizer = find_node('Organizer2')
onready var textInterfaceSplit:VSplitContainer = find_node('VSplitContainer')
onready var timePassContainer = find_node('TimePassContainer')
onready var controlsContainer = find_node('ControlsContainer')

var folderScene = load('res://ui/organizer/OrganizerFolder.tscn')
var entryScene = load('res://ui/organizer/OrganizerEntry.tscn')
var msgPopupScene = load('res://ui/MsgPopup.tscn')
var textInterface

var lastPopup

func _ready():
	textInterface = $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/TIE
	Event.textInterface = textInterface
	Event.connect("show_character", self, 'on_show_character')
	Event.connect("hide_character", self, 'on_hide_character')
	Event.connect("msg_popup", self, 'on_msg_popup')
	Event.connect('new_scene_loaded', self, 'on_new_scene_loaded')
	Event.connect("pass_time", self, 'on_pass_time')
	_on_DragSurface_resized()
	_on_TextBoxContainer_resized()
	GameState.UI = self
	var leftOrganizerName = GameState.settings.get('leftOrganizerName')
	var rightOrganizerName = GameState.settings.get('rightOrganizerName')
	if leftOrganizerName: load_left_organizer(leftOrganizerName)
	if rightOrganizerName: load_right_organizer(rightOrganizerName)

func on_pass_time(timeAmt:int):
	save_organizers()
	ProjectProcessor.process_projects()

func on_show_character(charImgPath):
	$CanvasLayer/Character.visible = true
	$CanvasLayer/Character.texture = load(charImgPath)
	
func on_hide_character():
	$CanvasLayer/Character.visible = false

func on_new_scene_loaded(newScene):
	pass

func _on_TextBoxContainer_resized():
	$CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/Blinker.position = $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer.rect_size - $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/Blinker.get_rect().size - Vector2(5,5)

func _on_DragSurface_resized():
	$CanvasLayer/Character.rect_global_position = $CanvasLayer/HBoxContainer/VSplitContainer/DragSurface.rect_global_position
	$CanvasLayer/Character.rect_size = $CanvasLayer/HBoxContainer/VSplitContainer/DragSurface.rect_size

func add_popup(item):
	if item.get_parent(): item.get_parent().remove_child(item)
	$PopupLayer.add_child(item)
	lastPopup = item

func on_msg_popup(data, sourceNode):
	var popup = msgPopupScene.instance()
	add_popup(popup)
	popup.set_text(data.get('msg'))
	popup.popup_centered(OS.get_window_size()/3*2)

func load_right_organizer(organizerName):
	load_organizer(organizerName, rightOrganizer)

func load_left_organizer(organizerName):
	load_organizer(organizerName, leftOrganizer)

func load_organizer(organizerName, organizer):
	if organizer.organizerDataName:
		var oldData = organizer.save()
		GameState.add_organizer(organizer.organizerDataName, oldData)
	var organizerData = GameState.get_organizer_data(organizerName)
	if organizerData:
		organizer.refresh_organizer_data(organizerData)

func save_organizers():
	var leftData = leftOrganizer.save()
	GameState.add_organizer(leftOrganizer.organizerDataName, leftData)
	var rightData = rightOrganizer.save()
	GameState.add_organizer(rightOrganizer.organizerDataName, rightData)
	
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

func call_attention_from_left(target:Control):
	var pointer = load("res://ui/CallAttention.tscn").instance()
	add_popup(pointer)
	pointer.call_attention_from_left(target)

func call_attention_from_right(target:Control):
	var pointer = load("res://ui/CallAttention.tscn").instance()
	add_popup(pointer)
	pointer.call_attention_from_right(target)
