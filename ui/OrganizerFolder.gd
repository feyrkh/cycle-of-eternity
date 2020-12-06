extends PanelContainer
class_name OrganizerFolder

onready var folderOpenIcon = $VBoxContainer/HBoxContainer/OpenIcon
onready var entryContainer = $VBoxContainer/EntryContainer

export var labelText = "folder"
var isOpen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.rect_pivot_offset = rect_size / 2
	entryContainer.visible = false
	$VBoxContainer/HBoxContainer/Label.text = labelText
	labelText = null

func get_entry_container():
	return entryContainer

func update_contents():
	if isOpen:
		print('updating folder icon (open)')
		folderOpenIcon.set_rotation(deg2rad(90))
		entryContainer.visible = true
	else: 
		print('updating folder icon (closed)')
		folderOpenIcon.set_rotation(deg2rad(0))
		entryContainer.visible = false

func on_dropped():
	yield(get_tree(),"idle_frame")
	update_contents()

func _on_TextureRect_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			toggle_folder()

func toggle_folder():
	print('toggling folder')
	isOpen = !isOpen
	update_contents()


func _on_OpenIcon_visibility_changed():
	yield(get_tree(),"idle_frame")
	update_contents()
