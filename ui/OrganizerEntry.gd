extends PanelContainer
class_name OrganizerEntry

export var labelText = 'entry'
export var draggable = true

onready var label = $HBoxContainer/Label
onready var editNameButton = $HBoxContainer/EditNameButton

var editBox:OrganizerLabelEdit

func _ready():
	print('loading')
	label.text = labelText
	labelText = null

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
	self.queue_free()
