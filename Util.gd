extends Node
class_name Util

static func clear_children(node:Node):
	for n in node.get_children():
		n.queue_free()

static func load_text_file(filename:String)->String:
	var file = File.new()
	file.open(filename, File.READ)
	var content = file.get_as_text()
	file.close()
	return content

static func load_json_file(filename:String)->Dictionary:
	var content = load_text_file(filename)
	return parse_json(content)
