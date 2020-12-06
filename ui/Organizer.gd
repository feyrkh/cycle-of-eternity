extends PanelContainer

onready var dragIndicator = $DragIndicator
onready var entryContainer = $'ScrollContainer/VBoxContainer'

var draggingEntry:Node = null
var dropPoint = null
enum {TOP_OF_LIST, AFTER_NODE, BEFORE_NODE}
var dropTargetType
var dropTarget:Node = null
var dropTargetIndex = 0
var dropContainer:Control = null


func _ready():
	for child in get_children():
		connect_drag_events_for_tree(child)

func _process(delta):
	if !Input.is_mouse_button_pressed(BUTTON_LEFT):
		stop_dropping()
	if draggingEntry:
		update_drag_indicator()
	else: 
		dragIndicator.visible = false
		set_process(false)

func stop_dropping():
	print('stopping drop operation')
	if draggingEntry && draggingEntry.has_method('unhighlight'): draggingEntry.unhighlight()
	dragIndicator.visible = false
	draggingEntry = null
	dropTarget = null
	dropContainer = null
	
func update_drag_indicator():
	dropTarget = self
	dropTargetIndex = 0
	dropTargetType = TOP_OF_LIST
	dropContainer = entryContainer
	var mousePos = get_local_mouse_position()
	if !self.get_rect().has_point(mousePos):
		dragIndicator.visible = false
		return
	dragIndicator.visible = true
	var childrenToScan = dropContainer.get_children()
	var stillScanning = true
	var rootOffset = Vector2(0,0)
	while stillScanning:
		stillScanning = false
		dropTargetType = TOP_OF_LIST
		for entry in childrenToScan:
			var entryRelativePosition = entry.rect_position - Vector2($ScrollContainer.scroll_horizontal, $ScrollContainer.scroll_vertical)
			if mousePos.y <= entryRelativePosition.y: # above me, put above me since it must be below other nodes or the loop would have ended
				if dropContainer != entryContainer: # if we're dropping into the top of a sub-folder, underline the subfolder header instead
					dragIndicator.position.x = entryRelativePosition.x + rootOffset.x #- dropContainer.rect_position.x
					dragIndicator.position.y = entryRelativePosition.y - 2 + rootOffset.y #- dropContainer.rect_position.y
					dropTargetIndex = dropContainer.get_child_count()
				else:
					dragIndicator.position.x = entryRelativePosition.x + rootOffset.x
					dragIndicator.position.y = entryRelativePosition.y - 2 + rootOffset.y
				return
				
			if mousePos.y <= entryRelativePosition.y + entry.rect_size.y: # overlapping me, figure out if we want to go above or below...unless I'm a folder, in which case go inside instead!
				# If we're overlapping a folder, get its entry container and restart from the start of its children (and descend indefinitely)
				if entry is OrganizerFolder: 
					#print('descending into folder')
					dropContainer = entry.get_entry_container()
					childrenToScan = dropContainer.get_children()
					rootOffset = rootOffset + (dropContainer.rect_global_position - entryContainer.rect_global_position) - Vector2($ScrollContainer.scroll_horizontal, $ScrollContainer.scroll_vertical)
					mousePos = dropContainer.get_local_mouse_position()
					stillScanning = true
					dropTargetIndex = 0
					dropTarget = dropContainer
					break
				# Otherwise we're overlapping an entry
				if mousePos.y <= entryRelativePosition.y + entry.rect_size.y/2: # overlapping top half
					dragIndicator.position.x = entryRelativePosition.x + rootOffset.x
					dragIndicator.position.y = entryRelativePosition.y - 2 + rootOffset.y
				else:
					dropTargetIndex += 1
					dragIndicator.position.x = entryRelativePosition.x + rootOffset.x
					dragIndicator.position.y = entryRelativePosition.y + entry.rect_size.y + 2 + rootOffset.y
				return
				
			if mousePos.y >  entryRelativePosition.y + entry.rect_size.y: # below me, put it below me but keep looking in case someone else wants to move it
				dragIndicator.position.x = entryRelativePosition.x + rootOffset.x
				dragIndicator.position.y = entryRelativePosition.y + entry.rect_size.y + 2 + rootOffset.y
				dropTarget = entry # We'll drop after me if we run off the end of the list
				dropTargetIndex += 1


#func _input(event):
#	if draggingEntry:
#		if event is InputEventMouseMotion:
#			handle_dragging(self)
#		elif event is InputEventMouseButton && event.button_index == BUTTON_LEFT and !event.pressed:
#			finish_dragging()

func connect_drag_events_for_tree(entry):
	if entry is Control: 
		print('setting up drag for ', entry)
		entry.set_drag_forwarding(self)
	for child in entry.get_children():
		connect_drag_events_for_tree(child)

func add_new_entry(entry:Node2D):
	if entry.has_method('connect_parent_container'): entry.connect_parent_container(self)
	
	add_child(entry)

#func on_drag_started(entry:Node2D):
#	draggingEntry = entry

#func handle_dragging(targetContainer):
#	var curMousePos = get_local_mouse_position()
	
#func finish_dragging():
#	print('dragging complete')
	
func can_drop_data(position, data):
#	print('checking local can drop for ', data)
	return (data is OrganizerEntry) or (data is OrganizerFolder)
	
func can_drop_data_fw(position, data, from_control):
#	print('checking can drop for ', data)
	return true

func drop_data_fw(position, data, from_control):
	print('checking drop at position ', position)
	# Check if dropTarget is a descendant of the item we're dropping
	var checkNode = dropTarget
	var invalidDrop = false
	while checkNode != null:
		if checkNode == data: 
			print('invalid drop, ', data, ' is an ancestor of ', dropTarget)
			invalidDrop = true
			break
		checkNode = checkNode.get_parent()
	print('invalidDrop=', invalidDrop, '; checked to see if ', data.name, ' is an ancestor of ', dropTarget.name)
	if !invalidDrop: # Only drop if we're actually moving...
		var entryParent = data.get_parent()
		if entryParent: entryParent.remove_child(data)
		print('dropping ', data, ' at position ', dropTargetIndex)
		dropContainer.add_child(data)
		dropContainer.move_child(data, dropTargetIndex)
		
#		if dropTargetType == TOP_OF_LIST: # Dropping at the top of the list
#			print('dropping ', data, ' at start of list')
#			dropContainer.add_child(data)
#			dropContainer.move_child(data, 0)
#		else: 
#			print('dropping ', data, ' below ', dropTarget)
#			dropContainer.add_child_below_node(dropTarget, data)
	else: print('tried dropping onto yourself, no op')
	stop_dropping()

func get_drag_data_fw(position, from_control):
	while from_control && !(from_control is OrganizerEntry) && !(from_control is OrganizerFolder):
		from_control = from_control.get_parent()
	if !from_control: return null
	draggingEntry = from_control
	dragIndicator.visible = true
	set_process(true)
	print('starting drag for ', from_control)
	return from_control
