extends Object
class_name OrganizerDataEntry

#var uuid=preload("res://addons/uuid.gd")


static func build(id, name:String, path, data, scene:String, entryFlags:int)->Dictionary:
	#if !id: id = v4()
	if path is String:
		path = (path).trim_prefix('/').split('/', false)
	var result = {'name':name, 'path':path, 'data':data, 'scene':scene, 'flags':entryFlags}
	if id: result['id'] = id
	return result

#static func serialize(entry:Dictionary):
#	return {'i':entry.id, 'n': entry.name, 'p':entry.path, 'd':entry.data, 's':entry.scene}
#
#static func deserialize(entry:Dictionary):
#	return {'id':entry.i, 'name':entry.n, 'path':entry.p, 'data': entry.d, 'scene':entry.s}

const MODULO_8_BIT = 256

static func getRandomInt():
  return randi() % MODULO_8_BIT

static func uuidbin():
  # 16 random bytes with the bytes on index 6 and 8 modified
  return [
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
	((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
  ]

static func v4():
  # 16 random bytes with the bytes on index 6 and 8 modified
  var b = uuidbin()

  return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
	# low
	b[0], b[1], b[2], b[3],

	# mid
	b[4], b[5],

	# hi
	b[6], b[7],

	# clock
	b[8], b[9],

	# clock
	b[10], b[11], b[12], b[13], b[14], b[15]
  ]
