extends PopupPanel

const DecreeOption = preload("res://decree/DecreeOption.tscn")

var decreeData
var decreeOrganizerNode

onready var decreeOptionsGrid:GridContainer = find_node('DecreeOptions')
onready var decreeResultsGrid:GridContainer = find_node('DecreeResults')
onready var decreeInputsGrid:GridContainer = find_node('DecreeInputs')
onready var decreeOptionsLabel:Label = find_node('DecreeOptionsLabel')
onready var decreeResultsLabel:Label = find_node('DecreeResultsLabel')
onready var decreeInputsLabel:Label = find_node('DecreeInputsLabel')
onready var decreeText:Label = find_node('DecreeText')
var optionNodeList = [] # array of all the DecreeOption nodes for easy reference


func _ready():
	if decreeData == null && get_parent() == get_tree().root: 
		show()
		decreeData = load("res://decree/DecreeData.gd").new()
		decreeData.baseInputResources = {'laborAdmin':3}
		decreeData.add_choice('workers', 'Number of Crews', [
			{'l':'one', 'out':{'workCrew':1, 'villageDiplomacy':-10}, 'in':{'laborAdmin':1}},
			{'l':'two', 'out':{'workCrew':2, 'villageDiplomacy':-25}, 'in':{'laborAdmin':2}},
			{'l':'three', 'out':{'workCrew':3, 'villageDiplomacy':-65}, 'in':{'laborAdmin':3}}
		])
		decreeData.add_choice('giftSize', 'Size of Gift', [
			{'l':'nominal', 'in':{'coin':-1}},
			{'l':'small', 'in':{'coin':-5},'out':{'villageDiplomacy':1}},
			{'l':'mediocre', 'in':{'coin':-25},'out':{'villageDiplomacy':4}},
			{'l':'large', 'in':{'coin':-100},'out':{'villageDiplomacy':15}},
			{'l':'enormous', 'in':{'coin':-500},'out':{'villageDiplomacy':70}},
		])
		decreeData.decreeTextTemplate = 'Workers are required! Send {workers} work crews to the {schoolName}. A {giftSize} gift will be provided in return.\n\n---\n\nCoins: {coin}\nVillage diplomacy change: {diplomacy}'
	var choiceData = decreeData.get_choice_data()
	for choiceId in choiceData.keys():
		add_choice(choiceId, choiceData[choiceId]['l'], choiceData[choiceId]['o'])
	update_decree_text()
	update_results()
	##visible = false
	update_rect_size()

func update_results():
	Util.clear_children(decreeResultsGrid)
	Util.clear_children(decreeInputsGrid)
	render_resource_grid(decreeResultsGrid, decreeResultsLabel, decreeData.get_selected_option_outputs(), null)
	render_resource_grid(decreeInputsGrid, decreeInputsLabel, decreeData.get_selected_option_inputs(), decreeData.get_applied_option_inputs())
	
func render_resource_grid(grid:GridContainer, sectionLabel:Label, results:Dictionary, appliedResources):
	if results.size() > 0: 
		grid.visible = true
		sectionLabel.visible = true
	var renamedResults = {}
	var renamedToOriginal = {}
	for k in results.keys():
		var renamedKey = GameState.get_resource_name(k)
		renamedResults[renamedKey] = results[k]
		renamedToOriginal[renamedKey] = k
	var sortedResultKeys = renamedResults.keys()
	sortedResultKeys.sort()
	for k in sortedResultKeys:
		var v = renamedResults[k]
		var label = Label.new()
		var value = Label.new()
		value.align = HALIGN_RIGHT
		label.set_text(k+'    ')
		var description = GameState.get_resource_description(renamedToOriginal[k])
		if description: label.hint_tooltip = description
		var amtText = GameState.get_resource_level(renamedToOriginal[k], v)
		if appliedResources != null:
			amtText = str(appliedResources.get(renamedToOriginal[k], '0')) + '/' + amtText
		value.set_text(amtText)
		grid.add_child(label)
		grid.add_child(value)


func update_rect_position():
	var screenCenter = get_viewport_rect().size / 2
	var halfSize = rect_size / 2
	rect_global_position = screenCenter - halfSize
	rect_global_position.y = 10

func update_rect_size():
	if optionNodeList.size() > 0: 
		find_node('DecreeOptionsContainer').visible = true
		decreeOptionsLabel.visible = true
		decreeOptionsGrid.visible = true
	yield(get_tree(), 'idle_frame')
	var optionsGridSize = decreeOptionsGrid.rect_global_position.x - rect_global_position.x + decreeOptionsGrid.rect_size.x+6
	var inputsGridSize = decreeInputsGrid.rect_global_position.x - rect_global_position.x + decreeInputsGrid.rect_size.x+6
	var resultsGridSize = decreeResultsGrid.rect_global_position.x - rect_global_position.x + decreeResultsGrid.rect_size.x+6
	self.rect_size.x = max(resultsGridSize, max(optionsGridSize, inputsGridSize))
	#print('grid.x=', decreeOptionsGrid.rect_global_position.x, '; popup.x=',  rect_global_position.x, '; grid.size.x=', decreeOptionsGrid.rect_size.x)
	#visible = true
	update_rect_position()
	
# choice format: [{'l':'Option 1', 'v':'1'}, {'l':'Option 2', 'v':'2'}, ...]
func add_choice(id:String, label:String, options:Array):
	var newLabel:Label = Label.new()
	newLabel.text = label+'    '
	decreeOptionsGrid.add_child(newLabel)
	var optionBtn:DecreeOption = DecreeOption.instance()
	optionBtn.id = id
	optionNodeList.append(optionBtn)
	decreeOptionsGrid.add_child(optionBtn)
	for option in options:
		# TODO: Handle identical ids or labels
		var labelText = option.get('l')
		if labelText == null: labelText = '(missing label)'
		var value = option.get('v')
		if value == null: value = labelText
		optionBtn.add_item(labelText)
	optionBtn.select(decreeData.get_selected_option(id).get('i', 0))
	optionBtn.connect("option_changed", self, 'option_changed')

func option_changed(optionId, optionIdx):
	decreeData.set_selected_option(optionId, optionIdx)
	update_results()
	update_decree_text()
	update_rect_size()
	
func update_decree_text():
	decreeText.text = decreeData.get_decree_text()
	
func _on_PopupPanel_popup_hide():
	#if decreeOrganizerNode: decreeOrganizerNode.data = decreeData.serialize()
	queue_free()
