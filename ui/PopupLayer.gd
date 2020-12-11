extends CanvasLayer



# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/Event".connect("show_query_popup", self, 'show_query_popup')

func show_query_popup(popup, target):
	print('adding popup to scene')
	self.add_child(popup)
	popup.show()
 
