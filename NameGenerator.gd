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
	if nameData:
		for i in range(10):
			generatedName = generate_name(nameData)
			if generatedName and !generatedNames.has(generatedName):
				generatedNames[generatedName] = 1
				return generatedName
	return '(unnamed %s)' % entityType
		
static func generate_name(nameData):
	if !nameData: return null
	var nameChoices = {}
	for k in nameData.keys():
		nameChoices[k] = nameData[k][randi()%nameData[k].size()]
	return capitalize(nameChoices['name'].format(nameChoices))
	
static func capitalize(name:String):
	name = name.replace('  ', ' ')
	var c=' '
	if name.begins_with("The"):
		pass
	for i in range(name.length()):
		if c == ' ':
			var newChar = name[i].capitalize()
			if name[i].length() > 0:
				name[i] = newChar
		if i < name.length(): 
			c = name[i]
	return name
