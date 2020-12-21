extends Resource

var filename
# choice['workers'] = {'l':'Number of Workers', 'o':[{'l':'1', 't':'one work crew', 'v':{'numWorkers':1, 'diplomacy':-10}}, 'l':'2', {'numWorkers':2, 'diplomacy':-25}, ...]}
var choice = {}
# selectedOptions['workers'] = {'numWorkers':1, 'diplomacy':-10}
var selectedOptions = {}
var decreeTextTemplate = 'This is a decree! You selected: {myOptionId}'
var appliedResources = {}

func get_choice_data():
	return choice

func add_choice(id:String, label:String, options:Array):
	choice[id] = {'l':label, 'o':options}

func get_selected_option(id:String):
	var selected = selectedOptions.get(id)
	if selected == null: 
		# if nothing has been selected, just use the first entry in the choice list
		var choiceData = choice.get(id)
		if choiceData == null: return {}
		var optionData = choiceData.get('o')
		if optionData == null or optionData.size() < 1: return {}
		selected = optionData[0]
		selected['i'] = 0
	return selected

func set_selected_option(id, optionIdx):
	selectedOptions[id] = choice[id]['o'][optionIdx]
	selectedOptions[id]['i'] = optionIdx

func get_selected_option_flavor_text():
	var mergedSelections = {}
	for optionId in choice.keys():
		var selectedOption = get_selected_option(optionId)
		# 't' is specifically for inserting into formatted 't'ext, so use it if present - otherwise default to the 'l'abel used by the dropdown list
		if selectedOption.has('t'): mergedSelections[optionId] = selectedOption['t']
		else: mergedSelections[optionId] = selectedOption['l']

	return mergedSelections

func get_selected_option_outputs():
	var mergedSelections = {}
	for optionId in choice.keys():
		var selectedOption = get_selected_option(optionId)
		for resourceName in selectedOption['v'].keys():
			var resourceValue = selectedOption['v'][resourceName]
			var mergedValue = mergedSelections.get(resourceName, 0) + resourceValue
			mergedSelections[resourceName] = mergedValue
	return mergedSelections

func get_decree_text():
	return decreeTextTemplate.format(get_selected_option_flavor_text()).format(get_selected_option_outputs()).format(GameState.settings)

func serialize():
	return {'cmd':'decree', 'f':filename, 'so':selectedOptions, 'ar':appliedResources}

func deserialize(data):
	init_from_file(data['f'])
	selectedOptions = data.get('so', {})

func init_from_file(filename):
	self.filename = filename
	var file = File.new()
	file.open(filename, file.READ)
	var text = file.get_as_text()
	file.close()
	var baseData = parse_json(text)
	decreeTextTemplate = baseData['t']
	choice = baseData['c']
