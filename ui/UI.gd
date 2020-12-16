extends Node2D

onready var leftOrganizer:Organizer = $CanvasLayer/HBoxContainer/VBoxContainer/Organizer
onready var rightOrganizer:Organizer = $CanvasLayer/HBoxContainer/Organizer2

var folderScene = load('res://ui/organizer/OrganizerFolder.tscn')
var entryScene = load('res://ui/organizer/OrganizerEntry.tscn')

func _ready():
	Event.textInterface = $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/TIE
	Event.connect("show_character", self, 'on_show_character')
	Event.connect("hide_character", self, 'on_hide_character')
	_on_DragSurface_resized()
	_on_TextBoxContainer_resized()

func on_show_character(charImgPath):
	$CanvasLayer/Character.visible = true
	$CanvasLayer/Character.texture = load(charImgPath)
	
func on_hide_character():
	$CanvasLayer/Character.visible = false

func _on_TextBoxContainer_resized():
	$CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/Blinker.position = $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer.rect_size - $CanvasLayer/HBoxContainer/VSplitContainer/TextBoxContainer/Blinker.get_rect().size - Vector2(5,5)

func _on_DragSurface_resized():
	$CanvasLayer/Character.rect_global_position = $CanvasLayer/HBoxContainer/VSplitContainer/DragSurface.rect_global_position
	$CanvasLayer/Character.rect_size = $CanvasLayer/HBoxContainer/VSplitContainer/DragSurface.rect_size

func new_folder(folderName:String, startsOpen=true):
	var item:OrganizerFolder = folderScene.instance()
	item.labelText = folderName
	item.isOpen = startsOpen
	return item

func new_item(itemName:String, itemData:Dictionary = {}):
	var item:OrganizerEntry = entryScene.instance()
	item.labelText = itemName
	item.data = itemData
	return item

func add_popup(item):
	if item.get_parent(): item.get_parent().remove_child(item)
	$PopupLayer.add_child(item)
