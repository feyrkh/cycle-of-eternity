extends Resource
class_name DecreeData 

var filename
var projectName = "Generic project"
# choice['workers'] = {'l':'Number of Workers', 'o':[{'l':'1', 't':'one work crew', 'in':{'coin':-10}, out':{'workCrew':1, 'diplomacy':-10}}, 'l':'2', 'out':{'workCrew':2, 'diplomacy':-25}, ...]}
var choice = {}
# selectedOptions['workers'] = {'workCrew':1, 'diplomacy':-10}
var selectedOptions = {}
var decreeTextTemplate = 'This is a decree! You selected: {myOptionId}'
var appliedResources = {}
var baseInputResources = {}
var baseOutputResources = {}
var projectComplete = false
var noProgressMade = false
var percentComplete = 0

func get_percent_complete(): return percentComplete
func get_progress_made(): return !noProgressMade
func set_entity_name(newName): projectName = newName
func get_entity_name(): return projectName

func get_is_project(): return true
func get_is_deleted(): 
	return projectComplete

func complete_project():
	Event.emit_signal("time_should_pause")
	Event.emit_signal("special_event", "Decree completed: "+projectName, 'decree_complete')
	projectComplete = true
	var resources_to_add = get_selected_option_outputs()
	var extra_options = get_selected_option_opts()
	print("Project complete: ", projectName, '; adding ', resources_to_add)
	for k in resources_to_add.keys():
		GameState.add_resource(k, resources_to_add[k], self, extra_options)

func on_organizer_entry_clicked(entry):
	cmd_decree(entry)

func cmd_decree(sourceNode):
	var decreePopup = load("res://decree/Decree.tscn").instance()
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

func get_selected_option_opts():
	return merge_selections_by_key('opt')

func get_selected_option_outputs():
	return merge_selections_by_key('out', baseOutputResources)
	
func get_selected_option_inputs():
	return merge_selections_by_key('in', baseInputResources)
	
func get_applied_option_inputs():
	return appliedResources
	
func merge_selections_by_key(key, baseResults={}):
	if !baseResults: baseResults = {}
	var mergedSelections = baseResults.duplicate()
	for optionId in choice.keys():
		var selectedOption = get_selected_option(optionId)
		for resourceName in selectedOption.get(key, {}).keys():
			var resourceValue = selectedOption[key][resourceName]
			var mergedValue = mergedSelections.get(resourceName, 0) + float(resourceValue)
			mergedSelections[resourceName] = mergedValue
	return mergedSelections

func consume_resources():
	projectComplete = true
	noProgressMade = true
	percentComplete = 0
	var required = get_selected_option_inputs()
	var percentPerInput = 1.0/required.size()
	for resourceName in required.keys():
		var neededResourceAmt = required[resourceName]
		var appliedResourceAmt = appliedResources.get(resourceName, 0)
		var remainingResourceAmt = neededResourceAmt - appliedResourceAmt
		var consumedResourceAmt = 0
		if remainingResourceAmt > 0:
			consumedResourceAmt = min(remainingResourceAmt, GameState.resources.get(resourceName, 0))
			if consumedResourceAmt > 0:
				noProgressMade = false
				GameState.consume_resource(resourceName, consumedResourceAmt, projectName)
				appliedResources[resourceName] = appliedResourceAmt + consumedResourceAmt
			projectComplete = projectComplete and (remainingResourceAmt == consumedResourceAmt)
		percentComplete += percentPerInput * ((appliedResourceAmt+consumedResourceAmt)/neededResourceAmt)
	if projectComplete:
		complete_project()

func get_decree_text():
	return decreeTextTemplate.format(get_selected_option_flavor_text()).format(get_selected_option_outputs()).format(GameState.settings)

func serialize():
	var retval = {'cmd':'decree', 'f':filename, 'name':projectName, 'so':selectedOptions, 'ar':appliedResources, 'dt':Util.DATATYPE_DECREE}
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
	choice = baseData.get('c', {})
	baseInputResources = baseData.get('in') # base resources just from the decree itself
	baseOutputResources = baseData.get('out') # base resources just from the decree itself
	projectName = baseData['name']
