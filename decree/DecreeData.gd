extends Resource
class_name DecreeData 

var filename
var projectName = "Generic project"
# choice['workers'] = {'l':'Number of Workers', 'o':[{'l':'1', 't':'one work crew', 'in':{'coin':-10}, out':{'numWorkers':1, 'diplomacy':-10}}, 'l':'2', 'out':{'numWorkers':2, 'diplomacy':-25}, ...]}
var choice = {}
# selectedOptions['workers'] = {'numWorkers':1, 'diplomacy':-10}
var selectedOptions = {}
var decreeTextTemplate = 'This is a decree! You selected: {myOptionId}'
var appliedResources = {}
var baseInputResources = {}
var projectComplete = false

func on_organizer_entry_clicked(entry):
	cmd_decree(entry)

func cmd_decree(sourceNode):
	var decreePopup = preload("res://decree/Decree.tscn").instance()
	decreePopup.decreeData = self
	if sourceNode: decreePopup.decreeOrganizerNode = sourceNode
	GameState.add_popup(decreePopup)
	decreePopup.popup_centered()
	
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
	return merge_selections_by_key('out')
	
func get_selected_option_inputs():
	return merge_selections_by_key('in', baseInputResources)
	
func merge_selections_by_key(key, baseResults={}):
	var mergedSelections = baseResults.duplicate()
	for optionId in choice.keys():
		var selectedOption = get_selected_option(optionId)
		for resourceName in selectedOption.get(key, {}).keys():
			var resourceValue = selectedOption[key][resourceName]
			var mergedValue = mergedSelections.get(resourceName, 0) + resourceValue
			mergedSelections[resourceName] = mergedValue
	return mergedSelections

func consume_resources():
	projectComplete = true
	var required = get_selected_option_inputs()
	for resourceName in required.keys():
		var neededResourceAmt = required[resourceName]
		var appliedResourceAmt = appliedResources.get(resourceName, 0)
		var remainingResourceAmt = neededResourceAmt - appliedResourceAmt
		if remainingResourceAmt > 0:
			var consumedResourceAmt = min(remainingResourceAmt, GameState.resources.get(resourceName))
			if consumedResourceAmt > 0:
				GameState.consume_resource(resourceName, consumedResourceAmt, projectName)
				appliedResources[resourceName] = appliedResourceAmt + consumedResourceAmt
				projectComplete = projectComplete && (remainingResourceAmt == consumedResourceAmt)
	if projectComplete:
		complete_project()

func complete_project():
	projectComplete = true
	print("Project complete: ", projectName)

func get_decree_text():
	return decreeTextTemplate.format(get_selected_option_flavor_text()).format(get_selected_option_outputs()).format(GameState.settings)

func serialize():
	var retval = {'cmd':'decree', 'f':filename, 'so':selectedOptions, 'ar':appliedResources, 'in':baseInputResources, 'dt':Util.DATATYPE_DECREE}
	if projectComplete: retval['!'] = true
	return retval

func deserialize(data):
	init_from_file(data['f'])
	projectName = data.get('name', 'Generic project')
	selectedOptions = data.get('so', {})
	appliedResources = data.get('ar', {})
	projectComplete = data.get('!', false)

func init_from_file(filename):
	self.filename = filename
	var file = File.new()
	file.open(filename, file.READ)
	var text = file.get_as_text()
	file.close()
	var baseData = parse_json(text)
	decreeTextTemplate = baseData['t']
	choice = baseData['c']
	baseInputResources = baseData['in'] # base resources just from the decree itself
