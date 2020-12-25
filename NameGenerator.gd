extends Node
class_name NameGenerator

const generatedNames = {}

func serialize():
	return generatedNames
	
func deserialize(data):
	generatedNames.clear()
	for k in data.keys():
		generatedNames[k] = 1

static func generate(entityType):
	var nameData = Util.load_json_file('res://data/name/%s.json'%entityType)
	var generatedName
	for i in range(10):
		generatedName = generate_name(nameData)
		if !generatedNames.has(generatedName):
			generatedNames[generatedName] = 1
			return generatedName
	return '(unnamed %s)' % entityType
		
static func generate_name(nameData):
	var nameChoices = {}
	for k in nameData.keys():
		nameChoices[k] = nameData[k][randi()%nameData[k].size()]
	return capitalize(nameChoices['name'].format(nameChoices))
	
static func capitalize(name:String):
	var c=' '
	for i in name.length():
		if c == ' ':
			name[i] = name[i].capitalize()
		c = name[i]
	return name
