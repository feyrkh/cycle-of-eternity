extends CanvasLayer

onready var mousePosition = $mousePosition

func _ready():
	$"/root/Event".connect("set_mouse_image", self, 'set_mouse_image')
	
func set_mouse_image(mouseImageNodeName):
	print('setting mouse image: ', mouseImageNodeName)
	var foundNode = false
	for child in mousePosition.get_children():
		#print('checking ', child.name, ' == ', mouseImageNodeName, ': ', child.name == mouseImageNodeName)
		if child.name == mouseImageNodeName: 
			foundNode = true
			child.visible = true
		else: child.visible = false
	if !foundNode: 
		#print('showing original mouse') 
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		#print('hiding original mouse') 
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		 #find_node('default').visible = true

func _process(_delta):
	mousePosition.position = get_viewport().get_mouse_position()
