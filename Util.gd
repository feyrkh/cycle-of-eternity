extends Node
class_name Util

static func clear_children(node:Node):
	for n in node.get_children():
		n.queue_free()
