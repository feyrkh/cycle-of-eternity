extends Container

var dragEnabled = false
var zoomEnabled = false

var dragging = null
var dragStart

var placeShadow
var placeItemData
var placeSourceNode
var placeShadowFlipped = false

onready var camera:Camera2D = $'../../../../Camera2D'
onready var zoomLevel = camera.zoom
onready var moveMultiplier = camera.zoom.x

func _ready():
	Event.connect('entering_combat', self, 'on_enter_combat')
	Event.connect('leaving_combat', self, 'on_leave_combat')
	Event.connect('place_item', self, 'on_place_item', [], CONNECT_DEFERRED)
	Event.connect('organizer_entry_clicked', self, 'on_organizer_entry_clicked') # so we can cancel item placement when they click on something else
	Event.connect('organizer_entry_toggled', self, 'on_organizer_entry_toggled') # so we can cancel item placement when they click on something else

func on_enter_combat(combatScene):
	dragEnabled = true
	zoomEnabled = true

func on_leave_combat(combatScene):
	dragEnabled = false
	zoomEnabled = false

func _on_DragSurface_gui_input(event):
	if placeShadow != null:
		handle_item_placement(event)
	else:
		handle_normal_input(event)

func on_organizer_entry_clicked(organizer, organizerEntryClicked):
	if placeShadow: cancel_place_item()
	
func on_organizer_entry_toggled(organizer, organizerEntryToggled, isTurnedOn):
	if placeShadow: cancel_place_item()

func handle_item_placement(event):
	placeShadow.global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			finish_place_item()
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			cancel_place_item()
		elif event.button_index == BUTTON_MIDDLE and event.pressed:
			placeShadowFlipped = !placeShadowFlipped
			placeShadow.scale.x = -placeShadow.scale.x
		elif event.is_pressed():
			# zoom in
			if event.button_index == BUTTON_WHEEL_UP:
				scale_shadow(0.1)
			# zoom out
			if event.button_index == BUTTON_WHEEL_DOWN:
				scale_shadow(-0.1)

func scale_shadow(amt):
	if !placeShadow: return
	if placeShadowFlipped:
		if placeShadow.scale.x > 0: placeShadow.scale.x = -placeShadow.scale.x
		placeShadow.scale.x = clamp(placeShadow.scale.x-amt, -2, -0.2)
	else: 
		if placeShadow.scale.x < 0: placeShadow.scale.x = -placeShadow.scale.x
		placeShadow.scale.x = clamp(placeShadow.scale.x+amt, 0.2, 2)
	placeShadow.scale.y = clamp(placeShadow.scale.y+amt, 0.2, 2)

func handle_normal_input(event):
	if dragging && event is InputEventMouseMotion:
		camera.position -= event.relative * moveMultiplier
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_MIDDLE and event.pressed and dragEnabled:
			dragging = event.position
		elif event.button_index == BUTTON_MIDDLE and !event.pressed:
			dragging = null
		elif event.is_pressed():
			# zoom in
			if event.button_index == BUTTON_WHEEL_UP:
				zoom_in()
			# zoom out
			if event.button_index == BUTTON_WHEEL_DOWN:
				zoom_out()

func finish_place_item():
	if placeItemData && placeSourceNode:
		Event.emit_signal('finalize_place_item', placeShadow.get_global_position(), placeShadow.get_scale(), placeShadow.get_rotation(), placeItemData, placeSourceNode)
	cancel_place_item()

func cancel_place_item():
	Event.emit_signal("cancel_place_item")
	if placeShadow: placeShadow.queue_free()
	placeShadow = null
	placeItemData = null
	placeSourceNode = null

func _on_DragSurface_mouse_exited():
	dragging = null

func on_place_item(itemShadow, itemData, sourceNode):
	self.placeShadow = itemShadow
	self.placeItemData = itemData
	self.placeSourceNode = sourceNode
	self.placeShadowFlipped = false

func zoom_in():
	if !zoomEnabled: return
	zoomLevel.x = max(0.1, zoomLevel.x*0.9)
	zoomLevel.y = max(0.1, zoomLevel.y*0.9)
	moveMultiplier = camera.zoom.x
	camera.zoom = zoomLevel
	Event.emit_signal('chakraZoom', zoomLevel)
	
func zoom_out():
	if !zoomEnabled: return
	zoomLevel.x = min(10, zoomLevel.x*1.1)
	zoomLevel.y = min(10, zoomLevel.y*1.1)
	moveMultiplier = camera.zoom.x
	camera.zoom = zoomLevel
	Event.emit_signal('chakraZoom', zoomLevel)
