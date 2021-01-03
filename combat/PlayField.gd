extends ColorRect

var dragging = false
onready var camera = get_tree().root.find_node('Camera2D', true, false)
var moveMultiplier = 1
var zoomLevel = Vector2.ONE

func can_drop_data(pos, data): 
	if data is Combatant or data is TargetLineFocus:
		return true
	return false

func drop_data(pos, data):
	if data is Combatant:
		data.rect_position = pos + self.rect_position
		Event.emit_signal("update_target_lines")
	elif data is TargetLineFocus:
		data.targetCombatant = null



func _on_PlayField_gui_input(event):
	if dragging && event is InputEventMouseMotion:
		camera.position -= event.relative# * moveMultiplier
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_MIDDLE and event.pressed:
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
#
#func zoom_in():
#	camera.zoom_at_point(0.9, camera.get_global_mouse_position())
#	zoomLevel = camera.zoom
#	Event.emit_signal('chakraZoom', zoomLevel)
#
#
#func zoom_out():
#	camera.zoom_at_point(1.1, camera.get_global_mouse_position())
#	zoomLevel = camera.zoom
#	Event.emit_signal('chakraZoom', zoomLevel)
#

func zoom_in():
	var originalMousePos = get_local_mouse_position()
	zoomLevel.x = max(0.1, zoomLevel.x*0.9)
	zoomLevel.y = max(0.1, zoomLevel.y*0.9)
	moveMultiplier = camera.zoom.x
	camera.zoom = zoomLevel
	var newMousePos = get_local_mouse_position()
	camera.position -= newMousePos - originalMousePos
	Event.emit_signal('chakraZoom', zoomLevel)

func zoom_out():
	var originalMousePos = get_local_mouse_position()
	zoomLevel.x = min(5, zoomLevel.x*1.1)
	zoomLevel.y = min(5, zoomLevel.y*1.1)
	moveMultiplier = camera.zoom.x
	camera.zoom = zoomLevel
	var newMousePos = get_local_mouse_position()
	camera.position -= newMousePos - originalMousePos
	Event.emit_signal('chakraZoom', zoomLevel)
