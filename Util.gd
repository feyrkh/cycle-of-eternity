extends Node
class_name Util

const DATATYPE_DICT = 0
const DATATYPE_DECREE = 1

const noDrag = 1<<0
const isToggle = 1<<1
const noDelete = 1<<2
const noEdit = 1<<3
const isProject = 1<<4
const isOpen = 1<<5

const flagNameMap = {
	'noDrag': noDrag,
	'isToggle': isToggle,
	'noDelete': noDelete,
	'noDel': noDelete,
	'noEdit': noEdit,
	'isProject': isProject,
	'isOpen': isOpen
}

static func build_entry_flags(flagNameArr:Array):
	if !flagNameArr is Array: 
		printerr('Unexpected flagNameArr, expected an array: ', flagNameArr)
		return 0
	var result = 0
	for flagName in flagNameArr:
		result = result | flagNameMap.get(flagName, 0)
	return result
			

static func clear_children(node:Node):
	for n in node.get_children():
		n.queue_free()

static func load_text_file(filename:String)->String:
	if !filename.begins_with('res://') and !filename.begins_with('user://'): return filename
	var file = File.new()
	file.open(filename, File.READ)
	var content = file.get_as_text()
	file.close()
	return content

static func load_json_file(filename:String)->Dictionary:
	var content = load_text_file(filename)
	return parse_json(content)

