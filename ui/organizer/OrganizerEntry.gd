extends PanelContainer
class_name OrganizerEntry

export var labelText = ''
export var canDrag = true
export var canDelete = true
export var isToggle = false

export(NodePath) var labelPath 
export(NodePath) var editNameButtonPath 
var label
var editNameButton
var data:Dictionary

var editBox:OrganizerLabelEdit
var containingOrganizer

func _ready():
	label = get_node(labelPath)
	editNameButton = get_node(editNameButtonPath)
	if labelText: label.text = labelText
	else: label.text = name
	labelText = null
	label.flat = !isToggle
	label.toggle_mode = isToggle
	

func is_organizer_entry(): return true

func call_attention():
	print('calling attention to myself!')
	for _i in range(20):
		modulate = Color.green
		yield(get_tree().create_timer(0.1),"timeout")
		modulate = Color.white
		yield(get_tree().create_timer(0.1),"timeout")
		
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
	if !canDelete:
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
	self.queue_free()


func _on_Label_pressed():
	$"/root/Event".emit_signal("organizer_entry_clicked", containingOrganizer, self)
	self.visible = false # easy way to lose focus
	self.visible = true


func _on_Label_toggled(button_pressed):
	$"/root/Event".emit_signal("organizer_entry_toggled", containingOrganizer, self, button_pressed)
	self.visible = false # easy way to lose focus
	self.visible = true
