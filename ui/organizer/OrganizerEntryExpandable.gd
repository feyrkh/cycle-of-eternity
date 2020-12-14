extends OrganizerEntry

export(NodePath) var contentsPath
var contents

func _ready():
	contents = get_node(contentsPath)
	while get_child_count() > 1:
		var child = get_child(get_child_count()-1)
		child.get_parent().remove_child(child)
		contents.add_child(child)
			

func _on_Label_pressed():
	contents.visible = !contents.visible


func _on_Label_toggled(button_pressed):
	contents.visible = !button_pressed
