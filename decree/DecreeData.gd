extends Resource

var filename
# choice['workers'] = {'l':'Number of Workers', 'o':[{'l':'1', 'v':{'numWorkers':1, 'diplomacy':-10}}, 'l':'2', {'numWorkers':2, 'diplomacy':-25}, ...]}
var choice = {}
# selectedOptions['workers'] = {'numWorkers':1, 'diplomacy':-10}
var selectedOptions = {}
var decreeTextTemplate = 'This is a decree! You selected: {myOptionId}'

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

func merge_selected_options():
	var mergedSelections = {}
	for optionId in choice.keys():
		var selectedOption = get_selected_option(optionId)
		mergedSelections[optionId] = selectedOption['l']
		for resourceName in selectedOption['v'].keys():
			var resourceValue = selectedOption['v'][resourceName]
			var mergedValue = mergedSelections.get(resourceName, 0) + resourceValue
			mergedSelections[resourceName] = mergedValue
	return mergedSelections
	
func get_decree_text():
	return decreeTextTemplate.format(merge_selected_options())

func serialize():
	return {'cmd':'decree', 'f':filename, 'so':selectedOptions}

func deserialize(data):
	var file = File.new()
	file.open(data['f'], file.READ)
	var text = file.get_as_text()
	file.close()
	var baseData = parse_json(text)
	choice = baseData['c']
	selectedOptions = data.get('so', {})
	decreeTextTemplate = baseData['t']
