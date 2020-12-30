extends PanelContainer
class_name OrganizerEntry

const OrganizerDataEntry = preload("res://ui/organizer/OrganizerDataEntry.gd")

signal entry_clicked()
signal entry_deleted()

export var labelText = ''

var id
var label
var editNameButton
var data
var blinkCount = 0

var entryFlags:int = 0

var editBox:OrganizerLabelEdit
var containingOrganizer
func set_containing_organizer(org): containingOrganizer = org

func _ready():
	label = find_node('Label')
	editNameButton = find_node('EditNameButton')
	if labelText: label.text = labelText
	else: label.text = name
	labelText = null
	label.flat = !get_is_toggle()
	label.toggle_mode = get_is_toggle()
	if get_no_edit(): editNameButton.visible = false
	if get_is_unread(): set_is_unread(true) # trigger visual indicators
	Event.connect("finalize_place_item", self, 'on_finalize_place_item')

func on_finalize_place_item(position, scale, rotation, itemData, sourceNode):
	if sourceNode == self:
		var placedCmd = itemData.get('placedCmd')
		itemData['cmd'] = placedCmd
		itemData.erase('placedCmd')
		itemData['pos'] = position
		itemData['posX'] = position.x
		itemData['posY'] = position.y
		itemData['scale'] = scale
		itemData['scaleX'] = scale.x
		itemData['scaleY'] = scale.y
		itemData['rot'] = rotation

func set_data(d):
	data = d

func get_no_drag(): return entryFlags & Util.noDrag
func get_is_toggle(): return entryFlags & Util.isToggle
func get_no_delete(): return entryFlags & Util.noDelete
func get_no_edit(): return entryFlags & Util.noEdit
func get_is_project(): return entryFlags & Util.isProject
func get_is_unread(): return entryFlags & Util.isUnread

func set_no_drag(val:bool):
	if val: entryFlags = entryFlags | Util.noDrag
	else: entryFlags = entryFlags & ~Util.noDrag
	var unreadIcon = find_node('UnreadIcon', true)
	if unreadIcon: unreadIcon.visible = val

func set_no_delete(val:bool):
	if val: entryFlags = entryFlags | Util.noDelete
	else: entryFlags = entryFlags & ~Util.noDelete

func set_is_toggle(val):
	if val: entryFlags = entryFlags | Util.isToggle
	else: entryFlags = entryFlags & ~Util.isToggle
	
func set_no_edit(val):
	if val: entryFlags = entryFlags | Util.noEdit
	else: entryFlags = entryFlags & ~Util.noEdit

func set_is_project(val):
	if val: entryFlags = entryFlags | Util.isProject
	else: entryFlags = entryFlags & ~Util.isProject

func set_is_unread(val):
	if val: entryFlags = entryFlags | Util.isUnread
	else: entryFlags = entryFlags & ~Util.isUnread
	var unreadIcon = find_node('UnreadIcon', true)
	if unreadIcon: 
		unreadIcon.visible = val
	# update folders above me
	if val: # unconditionally set folder read-ness
		var cur = self.get_parent()
		while cur:
			if cur.has_method('set_is_unread'): cur.set_is_unread(true)
			cur = cur.get_parent()
	else: # tell folders to check their children for read-ness
		var cur = self.get_parent()
		while cur:
			if cur.has_method('update_is_read_from_children'): cur.update_is_read_from_children()
			cur = cur.get_parent()


func get_label_text(): return label.text

func get_save_data(path):
	var saveData = OrganizerDataEntry.build(id, get_label_text(), path, data, get_scene_name(), entryFlags)
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
	if data and data is Dictionary:
		data['f_name'] = label.text
	elif data and data.has_method('set_entity_name'):
		data.set_entity_name(label.text)
	updateOrganizerDataFriendlyName()

func update_name_entered(newText):
	update_name_lost_focus()

func ask_to_delete():
	if get_no_delete():
		var noDeletePopup = load("res://ui/organizer/OrganizerDeleteRejectDialog.tscn").instance()
		noDeletePopup.dialog_text = "You may not delete "+label.text+"."
		var addLayer = self
		while addLayer.get_parent() && !(addLayer is CanvasLayer): addLayer = addLayer.get_parent()
		addLayer.add_child(noDeletePopup)
		noDeletePopup.popup()
		return
		
	var confirm:OrganizerDeleteConfirmationDialog = load("res://ui/organizer/OrganizerDeleteConfirmDialog.tscn").instance()
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
	updateOrganizerDataFriendlyName()
	set_is_unread(false)
	$"/root/Event".emit_signal("organizer_entry_clicked", containingOrganizer, self)
	emit_signal('entry_clicked')
	self.visible = false # easy way to lose focus
	self.visible = true


func _on_Label_toggled(button_pressed):
	updateOrganizerDataFriendlyName()
	set_is_unread(false)
	$"/root/Event".emit_signal("organizer_entry_toggled", containingOrganizer, self, button_pressed)
	self.visible = false # easy way to lose focus
	self.visible = true

func updateOrganizerDataFriendlyName():
	if data is Dictionary and data.has('cmd') and data.has('organizerName') and data['cmd'] == 'scene':
		var organizerData = GameState.get_organizer_data(data['organizerName'])
		if organizerData and organizerData.friendlyName != label.text:
			organizerData.friendlyName = label.text
	elif !(data is Dictionary) and data.has_method('set_entity_name'): 
		data.set_entity_name(label.text)

