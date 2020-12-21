extends PopupPanel

const DecreeOption = preload("res://decree/DecreeOption.tscn")

var decreeData
var decreeOrganizerNode

onready var decreeOptionsGrid:GridContainer = find_node('DecreeOptions')
onready var decreeResultsGrid:GridContainer = find_node('DecreeResults')
onready var decreeOptionsLabel:Label = find_node('DecreeOptionsLabel')
onready var decreeResultsLabel:Label = find_node('DecreeResultsLabel')
onready var decreeText:Label = find_node('DecreeText')
var optionNodeList = [] # array of all the DecreeOption nodes for easy reference


func _ready():
	if decreeData == null && get_parent() == get_tree().root: 
		show()
		decreeData = load("res://decree/DecreeData.gd").new()
		decreeData.add_choice('workers', 'Number of Crews', [
			{'l':'one', 'v':{'numWorkers':1, 'villageDiplomacy':-10}},
			{'l':'two', 'v':{'numWorkers':2, 'villageDiplomacy':-25}},
			{'l':'three', 'v':{'numWorkers':3, 'villageDiplomacy':-65}}
		])
		decreeData.add_choice('giftSize', 'Size of Gift', [
			{'l':'nominal', 'v':{'coin':-1}},
			{'l':'small', 'v':{'coin':-5,'villageDiplomacy':1}},
			{'l':'mediocre', 'v':{'coin':-25,'villageDiplomacy':4}},
			{'l':'large', 'v':{'coin':-100,'villageDiplomacy':15}},
			{'l':'enormous', 'v':{'coin':-500,'villageDiplomacy':70}},
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
	var results = decreeData.get_selected_option_outputs()
	if results.size() > 0: 
		decreeResultsGrid.visible = true
		decreeResultsGrid.visible = true
	var sortedResultKeys = results.keys()
	sortedResultKeys.sort()
	for k in sortedResultKeys:
		var v = results[k]
		var label = Label.new()
		label.margin_right += 10
		var value = Label.new()
		value.align = HALIGN_RIGHT
		label.set_text(GameState.get_resource_name(k))
		var description = GameState.get_resource_description(k)
		if description: label.hint_tooltip = description
		value.set_text(GameState.get_resource_level(k, v))
		decreeResultsGrid.add_child(label)
		decreeResultsGrid.add_child(value)


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
	self.rect_size.x = decreeOptionsGrid.rect_global_position.x - rect_global_position.x + decreeOptionsGrid.rect_size.x+6
	#print('grid.x=', decreeOptionsGrid.rect_global_position.x, '; popup.x=',  rect_global_position.x, '; grid.size.x=', decreeOptionsGrid.rect_size.x)
	#visible = true
	update_rect_position()
	
# choice format: [{'l':'Option 1', 'v':'1'}, {'l':'Option 2', 'v':'2'}, ...]
func add_choice(id:String, label:String, options:Array):
	var newLabel:Label = Label.new()
	newLabel.text = label
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
	if decreeOrganizerNode: decreeOrganizerNode.data = decreeData.serialize()
	queue_free()
