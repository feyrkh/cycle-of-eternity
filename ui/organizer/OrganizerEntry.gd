extends PanelContainer
class_name OrganizerEntry

const OrganizerDataEntry = preload("res://ui/organizer/OrganizerDataEntry.gd")

signal entry_clicked()
signal entry_deleted()

export var labelText = ''

var id
var label
var editNameButton
var data:Dictionary
var blinkCount = 0

var editBox:OrganizerLabelEdit
var containingOrganizer

func _ready():
	label = find_node('Label')
	editNameButton = find_node('EditNameButton')
	if labelText: label.text = labelText
	else: label.text = name
	labelText = null
	label.flat = !get_is_toggle()
	label.toggle_mode = get_is_toggle()
	if get_no_edit(): editNameButton.visible = false

func get_no_drag(): return data.get('noDrag', false)
func get_is_toggle(): return data.get('isToggle', false)
func get_no_delete(): return data.get('noDel', false)
func get_no_edit(): return data.get('noEdit')
func get_is_project(): return data.get('isProject', false)

func set_no_drag(val):
	if val: data['noDrag'] = true
	else: data.erase('noDrag')

func set_no_delete(val):
	if val: data['noDel'] = true
	else: data.erase('noDel')

func set_is_toggle(val):
	if val: data['isToggle'] = true
	else: data.erase('isToggle')
	
func set_no_edit(val):
	if val: data['noEdit'] = true
	else: data.erase('noEdit')

func set_is_project(val):
	if val: data['isProject'] = true
	else: data.erase['isProject']

func get_label_text(): return label.text

func get_save_data(path):
	var saveData = OrganizerDataEntry.build(id, get_label_text(), path, data, get_scene_name())
	return saveData
	
func get_scene_name():
	return 'OrganizerEntry'

func is_organizer_entry(): return true

func call_attention():
	print('calling attention to myself!')
	GameState.attentionTimer.connect('timeout', self, 'blink')
	blinkCount = 10

func blink():
	blinkCount = blinkCount - 1
	if blinkCount <= 0:
		modulate = Color.white
		GameState.attentionTimer.disconnect('timeout', self, 'blink')
		return
	if modulate == Color.white:
		modulate = Color.green
	else:
		modulate = Color.white
		
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
		var noDeletePopup = preload("res://ui/organizer/OrganizerDeleteRejectDialog.tscn").instance()
		noDeletePopup.dialog_text = "You may not delete "+label.text+"."
		var addLayer = self
		while addLayer.get_parent() && !(addLayer is CanvasLayer): addLayer = addLayer.get_parent()
		addLayer.add_child(noDeletePopup)
		noDeletePopup.popup()
		return
		
	var confirm:OrganizerDeleteConfirmationDialog = preload("res://ui/organizer/OrganizerDeleteConfirmDialog.tscn").instance()
	confirm.dialog_text = "Are you sure you want to delete "+label.text+"?\n\nThis is irreversible."
	confirm.connect("confirmed", self, 'really_delete')
	var addLayer = self
	while addLayer.get_parent() && !(addLayer is CanvasLayer): addLayer = addLayer.get_parent()
	addLayer.add_child(confirm)
	confirm.popup()
	
func really_delete():
	emit_signal('entry_deleted')
	self.queue_free()


func _on_Label_pressed():
	$"/root/Event".emit_signal("organizer_entry_clicked", containingOrganizer, self)
	emit_signal('entry_clicked')
	self.visible = false # easy way to lose focus
	self.visible = true


func _on_Label_toggled(button_pressed):
	$"/root/Event".emit_signal("organizer_entry_toggled", containingOrganizer, self, button_pressed)
	self.visible = false # easy way to lose focus
	self.visible = true
