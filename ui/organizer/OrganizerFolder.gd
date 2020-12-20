extends PanelContainer
class_name OrganizerFolder

onready var folderOpenIcon = $VBoxContainer/HBoxContainer/OpenIcon
onready var entryContainer = $VBoxContainer/EntryContainer
onready var label = $VBoxContainer/HBoxContainer/Label
onready var editNameButton = $VBoxContainer/HBoxContainer/EditNameButton

export var labelText = "folder"

var id
var data = {}

var editBox:OrganizerLabelEdit
var containingOrganizer



func set_no_drag(val):
	if val: data['noDrag'] = true
	else: data.erase('noDrag')

func set_no_delete(val):
	if val: data['noDel'] = true
	else: data.erase('noDel')
	
func set_is_open(val):
	if val: data['isOpen'] = true
	else: data.erase('isOpen')

func set_no_edit(val):
	if val: data['noEdit'] = true
	else: data.erase('noEdit')

func get_no_drag(): return data.get('noDrag', false)
func get_no_delete(): return data.get('noDel', false)
func get_is_open(): return data.get('isOpen')
func get_no_edit(): return data.get('noEdit')

# Called when the node enters the scene tree for the first time.
func _ready():
	self.rect_pivot_offset = rect_size / 2
	entryContainer.visible = false
	if labelText: label.text = labelText
	else: label.text = name
	labelText = null
	for child in get_children():
		if child.has_method('is_organizer_entry') && child.is_organizer_entry():
			self.remove_child(child)
			entryContainer.add_child(child)

func is_organizer_entry(): return true

func get_label_text(): return label.text

func get_save_data(path):
	var saveData = OrganizerDataEntry.build(null, get_label_text(), path, data, get_scene_name())
	return saveData

func get_scene_name():
	return 'OrganizerFolder'
	
func get_entry_container():
	return entryContainer

func call_attention():
	for _i in range(20):
		self_modulate = Color.green
		yield(get_tree().create_timer(0.1),"timeout")
		self_modulate = Color.white
		yield(get_tree().create_timer(0.1),"timeout")
		

func collapse():
	data.erase('isOpen')
	update_contents()
	
func expand():
	data['isOpen'] = true
	update_contents()

func add_item_top(item):
	entryContainer.add_child(item)
	entryContainer.move_child(item, 0)
	
func add_item_bottom(item):
	entryContainer.add_child(item)

func update_contents():
	if get_no_edit(): editNameButton.visible = false
	if data.get('isOpen'):
		#print('updating folder icon (open)')
		folderOpenIcon.set_rotation(deg2rad(90))
		entryContainer.visible = true
	else: 
		#print('updating folder icon (closed)')
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
	if data.get('isOpen'): data.erase('isOpen')
	else: data['isOpen'] = true
	update_contents()

func _on_OpenIcon_visibility_changed():
	update_contents() # needed when reloading an organizer that has entries which haven't changed
	yield(get_tree(),"idle_frame")
	update_contents() # needed to update the open/closed icon on a folder when a new organizer is added

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
	if get_no_delete():
		var noDeletePopup = OrganizerDeleteRejectDialog.new()
		noDeletePopup.dialog_text = "You may not delete "+label.text+"."
		var addLayer = self
		while addLayer.get_parent() && !(addLayer is CanvasLayer): addLayer = addLayer.get_parent()
		addLayer.add_child(noDeletePopup)
		noDeletePopup.popup()
		return
	var confirm:OrganizerDeleteConfirmationDialog = OrganizerDeleteConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to delete "+label.text+"?\n\nThis is irreversible."
	confirm.connect("confirmed", self, 'really_delete')
	var addLayer = self
	while addLayer.get_parent() && !(addLayer is CanvasLayer): addLayer = addLayer.get_parent()
	addLayer.add_child(confirm)
	confirm.popup()
	
func really_delete():
	var prevNode = self
	for child in entryContainer.get_children():
		entryContainer.remove_child(child)
		get_parent().add_child_below_node(prevNode, child)
		prevNode = child
	yield(get_tree(), 'idle_frame')
	self.queue_free()
