extends PanelContainer

export(NodePath) var entryContainerPath
onready var dragIndicator = $DragIndicator
onready var entryContainer = get_node(entryContainerPath)

var draggingEntry:Node = null
enum {TOP_OF_LIST, BOTTOM_OF_LIST, AFTER_NODE, BEFORE_NODE}
var dropTargetType
var dropTarget:Node = null
var dropContainer:Control = null

const OrganizerFolderScene = preload('./OrganizerFolder.tscn')
const OrganizerEntryScene = preload('./OrganizerEntry.tscn')

func _ready():
	for child in get_children():
		if child.has_method('is_organizer_entry') && child.is_organizer_entry():
			self.remove_child(child)
			entryContainer.add_child(child)
		connect_drag_events_for_tree(child)

func _process(delta):
	if !Input.is_mouse_button_pressed(BUTTON_LEFT):
		stop_dropping()
	if !draggingEntry:
		dragIndicator.visible = false
		set_process(false)

func _input(event):
	if draggingEntry:
		update_drag_indicator()
		
func stop_dropping():
	print('stopping drop operation')
	if draggingEntry && draggingEntry.has_method('unhighlight'): draggingEntry.unhighlight()
	dragIndicator.visible = false
	draggingEntry = null
	dropTarget = null
	dropContainer = null
	
func update_drag_indicator():
	dropTarget = self
	dropTargetType = TOP_OF_LIST
	dropContainer = entryContainer
	var mousePos = get_global_mouse_position()
	if !self.get_global_rect().has_point(mousePos-Vector2(0, 7)) or !self.get_global_rect().has_point(mousePos+Vector2(0, 7)) :
		dragIndicator.visible = false
		dropTarget = null
		dropContainer = null
		return
	#print(mousePos, ' contained in ', self.get_global_rect())
	dragIndicator.visible = true
	var childrenToScan = dropContainer.get_children()
	var stillScanning = true
	var rootOffset = Vector2(0,0)
	while stillScanning:
		stillScanning = false
		dropTargetType = TOP_OF_LIST
		for entry in childrenToScan:
			var entryPosition = entry.rect_global_position
#			if mousePos.y < entryPosition.y: # above me - we must be above the first item of a container, drop to the top of the list and underline container
#				dropTargetType = TOP_OF_LIST
#				dropTarget = dropContainer
#				dragIndicator.global_position = dropContainer.get_global_rect().position - Vector2(0, 2)
#				return
			if !(entry is OrganizerFolder): # handle overlaps with non-folders
				if mousePos.y < entryPosition.y + entry.rect_size.y/2: # overlapping my top half, insert before me
					dropTargetType = BEFORE_NODE
					dropTarget = entry
					dragIndicator.global_position = dropTarget.get_global_rect().position - Vector2(0, 2)
					return
				if mousePos.y <= entryPosition.y + entry.rect_size.y: # overlapping my bottom half, insert after me
					dropTargetType = AFTER_NODE
					dropTarget = entry
					dragIndicator.global_position = dropTarget.get_global_rect().position + Vector2(0, dropTarget.get_global_rect().size.y + 2)
					return
				# this might be the last item in the list...set to drop after this just in case, it will get reset otherwise
				dropTargetType = AFTER_NODE
				dropTarget = entry
				dragIndicator.global_position = dropTarget.get_global_rect().position + Vector2(0, dropTarget.get_global_rect().size.y + 2)
			elif(entry is OrganizerFolder): # handle folders
				if mousePos.y >= entryPosition.y && mousePos.y <= entryPosition.y + dropContainer.rect_size.y:
					if !entry.isOpen or entry.get_entry_container().get_child_count() == 0: # if the folder is closed (or has 0 items), it's easy - just add to the end of its list
						# Allow a few pixels space on the top so we can drop above lists that are at the top of another list
						if mousePos.y <= entryPosition.y + 8:
							dropTargetType = BEFORE_NODE
							dropTarget = entry
							dragIndicator.global_position = dropTarget.get_global_rect().position - Vector2(0, 2)
							return
						if mousePos.y >= entryPosition.y && mousePos.y <= entryPosition.y + entry.rect_size.y:
							dropContainer = entry.get_entry_container()
							dropTargetType = BOTTOM_OF_LIST
							dropTarget = entry.get_entry_container()
							var highlightTarget = entry
							dragIndicator.global_position = highlightTarget.get_global_rect().position + Vector2(25, highlightTarget.rect_size.y - 12)
							return
					else: # if the folder is open and we're overlapping it, we have to recurse
						# Allow a few pixels space on the top so we can drop above lists that are at the top of another list
						if mousePos.y <= entryPosition.y + 8:
							dropTargetType = BEFORE_NODE
							dropTarget = entry
							dragIndicator.global_position = dropTarget.get_global_rect().position - Vector2(0, 2)
							return
						if mousePos.y >= entryPosition.y && mousePos.y <= entryPosition.y + entry.rect_size.y:
							dropContainer = entry.get_entry_container()
							childrenToScan = dropContainer.get_children()
							stillScanning = true
							break

func connect_drag_events_for_tree(entry):
	if entry is Control and !entry.name.ends_with('Target'):
		if entry.has_meta('containingOrganizer'): entry.containingOrganizer = self
#		print('setting up drag for ', entry)
		entry.set_drag_forwarding(self)
	for child in entry.get_children():
		connect_drag_events_for_tree(child)

func add_new_entry(entry:Node2D):
	if entry.has_method('connect_parent_container'): entry.connect_parent_container(self)
	add_child(entry)

func can_drop_data(position, data):
	return (data is OrganizerEntry) or (data is OrganizerFolder)

func can_drop_data_fw(position, data, from_control):
	return (data is OrganizerEntry) or (data is OrganizerFolder)

func drop_data_fw(position, data, from_control):
	if dropTarget == null || dropContainer == null || data == null: return
#	print('checking drop at position ', position)
	# Check if dropTarget is a descendant of the item we're dropping
	var checkNode = dropTarget
	var invalidDrop = dropTarget == self
#	print('checking for invalid drop: ', dropTarget.name, ' vs ', data.name, ' (preemptive check: ', invalidDrop, ')')
	while checkNode != null:
		if checkNode == data: 
#			print('invalid drop, ', data, ' is an ancestor of ', dropTarget)
			invalidDrop = true
			break
		checkNode = checkNode.get_parent()
#	print('invalidDrop=', invalidDrop, '; checked to see if ', data.name, ' is an ancestor of ', dropTarget.name)
	if !invalidDrop: # Only drop if we're actually moving...
		var entryParent = data.get_parent()
		if entryParent: entryParent.remove_child(data)
		dropContainer.add_child(data)
		match dropTargetType:
			TOP_OF_LIST: dropContainer.move_child(data, 0)
			BOTTOM_OF_LIST: pass
			BEFORE_NODE: dropContainer.move_child(data, dropTarget.get_index())
			AFTER_NODE: dropContainer.move_child(data, dropTarget.get_index()+1)
		if data.has_method('on_dropped'): data.on_dropped()
	else: print('tried dropping onto yourself, no op')
	stop_dropping()

func get_drag_data_fw(position, from_control):
	while from_control && !(from_control is OrganizerEntry) && !(from_control is OrganizerFolder):
		from_control = from_control.get_parent()
	if !from_control || !from_control.canDrag: return null
	draggingEntry = from_control
	dragIndicator.visible = true
	set_process(true)
	if draggingEntry && draggingEntry.has_method('highlight'): draggingEntry.highlight()
	print('starting drag for ', from_control)
	return from_control

func _on_NewFolderButton_pressed():
	var newFolder = OrganizerFolderScene.instance()
	entryContainer.add_child(newFolder)
	connect_drag_events_for_tree(newFolder)
	yield(get_tree(),"idle_frame")
	newFolder.edit_name()
