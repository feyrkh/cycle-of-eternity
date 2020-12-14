extends MarginContainer

var dragging = null
var dragStart

onready var camera:Camera2D = $'../../../../Camera2D'
onready var zoomLevel = camera.zoom
onready var moveMultiplier = camera.zoom.x

func _on_DragSurface_gui_input(event):
	if dragging && event is InputEventMouseMotion:
		camera.position -= event.relative * moveMultiplier
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

func _on_DragSurface_mouse_exited():
	dragging = null

func zoom_in():
	zoomLevel.x = max(0.1, zoomLevel.x*0.9)
	zoomLevel.y = max(0.1, zoomLevel.y*0.9)
	moveMultiplier = camera.zoom.x
	camera.zoom = zoomLevel
	$'/root/Event'.emit_signal('chakraZoom', zoomLevel)
	
func zoom_out():
	zoomLevel.x = min(10, zoomLevel.x*1.1)
	zoomLevel.y = min(10, zoomLevel.y*1.1)
	moveMultiplier = camera.zoom.x
	camera.zoom = zoomLevel
	$'/root/Event'.emit_signal('chakraZoom', zoomLevel)
