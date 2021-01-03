extends TextureButton

onready var offsetCamera:Camera2D = get_tree().root.find_node("Camera2D")
onready var area2d:Area2D = get_tree().root.find_node("QueryToolCursor")

var drawLayer
var highlighted = null
var querying = false
var queryTimer = 0.1

func _ready():
	set_process(false)
	drawLayer = self
	while drawLayer.get_parent() && !(drawLayer is CanvasLayer): drawLayer = drawLayer.get_parent()

func _on_TextureButton_pressed():
	querying = true
	set_process(true)
	#area2d.visible = true
	$"/root/Event".emit_signal("set_mouse_image", 'query')
	print('Entered query mode')
	
func _process(delta):
	area2d.position = offsetCamera.get_global_mouse_position()
	if Input.is_action_just_pressed('query_click'):
		queryHighlightedItem()
	queryTimer -= max(0.1, delta)
	if queryTimer <= 0:
		queryTimer = 0.1
		_on_Timer_timeout()

func queryHighlightedItem():
	querying = false
	area2d.visible = false
	print('Leaving query mode')
	$"/root/Event".emit_signal("set_mouse_image", 'default')
	set_process(false)
	if !highlighted: return
	if highlighted.has_method('query_popup'): highlighted.query_popup()
	if highlighted.has_method('unhighlight'):
		highlighted.unhighlight()
	if highlighted.has_method('query_item'): highlighted.query_item()

func _on_Timer_timeout():
	var nearby = area2d.get_overlapping_bodies()
	#print('found ', nearby.size(), ' nearby items')
	var shortestDist = 2147483647
	var closestItem = null
	for node in nearby:
		var dist = area2d.global_position.distance_squared_to(node.global_position)
		if dist <= shortestDist: 
			shortestDist = dist
			closestItem = node
	if highlighted == closestItem: return
	print('unhighlighting: ', highlighted)
	if highlighted && highlighted.has_method('unhighlight'):
		highlighted.unhighlight()
	highlighted = closestItem
	print('highlighting: ', highlighted)
	if highlighted && highlighted.has_method('highlight'):
		highlighted.highlight()
