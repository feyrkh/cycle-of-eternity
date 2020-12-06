extends PanelContainer
class_name OrganizerFolder

onready var folderOpenIcon = $VBoxContainer/HBoxContainer/OpenIcon
onready var entryContainer = $VBoxContainer/EntryContainer
onready var label = $VBoxContainer/HBoxContainer/Label
onready var editNameButton = $VBoxContainer/HBoxContainer/EditNameButton

export var labelText = "folder"
export var draggable = true

var isOpen = false
var editBox:OrganizerLabelEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	self.rect_pivot_offset = rect_size / 2
	entryContainer.visible = false
	label.text = labelText
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
	if(get_tree()):
		yield(get_tree(),"idle_frame")
		update_contents()

func _on_TextureRect_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			toggle_folder()


func _on_Label_pressed():
	toggle_folder()

func toggle_folder():
	print('toggling folder')
	isOpen = !isOpen
	update_contents()

func _on_OpenIcon_visibility_changed():
	yield(get_tree(),"idle_frame")
	update_contents()

func highlight():
	self.modulate = Color.yellow

func unhighlight():
	self.modulate = Color.white

func edit_name():
	label.visible = false
	editNameButton.visible = false
	editBox = OrganizerLabelEdit.new()
	label.get_parent().add_child(editBox)
	editBox.text = label.text
	editBox.grab_focus()
	editBox.size_flags_horizontal = SIZE_EXPAND_FILL
	editBox.select_all()
	editBox.connect("focus_exited", self, 'update_name_lost_focus')
	editBox.connect("text_entered", self, 'update_name_entered')
	
func update_name_lost_focus():
	label.text = editBox.text
	editBox.visible = false
	label.visible = true
	editNameButton.visible = true
	editBox.queue_free()

func update_name_entered(newText):
	update_name_lost_focus()

func ask_to_delete():
	var confirm:OrganizerDeleteConfirmationDialog = OrganizerDeleteConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to delete "+label.text+"?\n\nThis is irreversible."
	confirm.connect("confirmed", self, 'really_delete')
	get_tree().root.add_child(confirm)
	confirm.popup()
	
func really_delete():
	var prevNode = self
	for child in entryContainer.get_children():
		entryContainer.remove_child(child)
		get_parent().add_child_below_node(prevNode, child)
		prevNode = child
	yield(get_tree(), 'idle_frame')
	self.queue_free()
