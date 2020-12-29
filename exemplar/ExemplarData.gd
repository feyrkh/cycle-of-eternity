extends Node
class_name ExemplarData

const strStats = ['boneStr', 'armStr', 'armEnd', 'legStr', 'legEnd', 'gripStr', 'gripEnd', 'coreStr', 'coreEnd']
const dexStats = ['moveSpd', 'jumpAgi', 'attackAgi', 'attackSpd', 'defendAgi', 'reactSpd']
const intStats = ['perceive', 'insight', 'synthesis']
const willStats = ['emptyMind', 'focusMind', 'resistFatigue']

var entityName
var stats = {}
var gender

func get_entity_name():
	return entityName

func on_resource_create(newName, createOpts):
	var defaultMed = 50
	var defaultStdev = 16.6
	for stat in strStats: generate_stat(stat, createOpts.get('strMed', defaultMed), createOpts.get('strStdev', defaultStdev))
	for stat in dexStats: generate_stat(stat, createOpts.get('dexMed', defaultMed), createOpts.get('dexStdev', defaultStdev))
	for stat in intStats: generate_stat(stat, createOpts.get('intMed', defaultMed), createOpts.get('intStdev', defaultStdev))
	for stat in willStats: generate_stat(stat, createOpts.get('willMed', defaultMed), createOpts.get('willStdev', defaultStdev))
	gender = createOpts.get('gender', Util.rand_choice(['m', 'f']))
	# ignoring newName
	entityName = NameGenerator.generate('disciple_'+gender)
	
func generate_stat(statName, median, stdev):
	var value = Util.bell_curve(median, stdev, randf())
	stats[statName] = value
	var maxValue = (Util.bell_curve(0.3, 0.075, randf()) + 1) * value
	if maxValue < value: maxValue = value
	stats['max_'+statName] = maxValue
	
func on_organizer_entry_clicked(entry):
	print('opening disciple: ', entityName)
	print(stats)

func serialize():
	var retval = {'cmd':'exemplar', 'dt':Util.DATATYPE_EXEMPLAR, 'stats':stats, 'g':gender}
	return retval

func deserialize(data):
	init_from_file(data['f'])
	entityName = data.get('name', 'Unnamed Exemplar')
	stats = data.get('stats', {})
	gender = data.get('g', 'f')

func init_from_file(filename):
	self.filename = filename
	var file = File.new()
	file.open(filename, file.READ)
	var text = file.get_as_text()
	file.close()
	var baseData = parse_json(text)
	entityName = baseData['name']
