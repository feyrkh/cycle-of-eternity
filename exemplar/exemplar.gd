extends Control

var sourceData # type=ExemplarData
var orgEntryNode
var originalOrganizerName
var originalOrganizerData
var trainingOrganizerData

var selectedTrainingOption = 0 # save so it doesn't jump around when time passes
var selectedCountOption = 0
var selectedRepeatOption = true

var selectedTab = 0 # save so it doesn't jump around when time passes
var shouldPulse = true

var trainingOptions = [] # transient, refreshed by load_training_options_from_location

onready var trainingMethodSelect:OptionButton = find_node('TrainingMethodSelect')
onready var countSelect:OptionButton = find_node('CountSelect')
onready var repeatTrainingButton:CheckBox = find_node("RepeatTraining")
onready var addToPlanButton:Button = find_node("AddToPlanButton")
onready var trainingOrganizer = find_node("TrainingOrganizer")
onready var exemplarStatus = find_node("ExemplarStatus")

func update_label(labelName, newText):
	var label = find_node(labelName)
	if !label:
		printerr("Could not find label=%s, wanted to update it to '%s'"%[labelName, newText])
		return
	label.text = str(newText)

func _ready():
	self.rect_min_size = GameState.UI.dragSurface.rect_size
	
	if !sourceData:
		sourceData = load('res://exemplar/ExemplarData.gd').new()
		sourceData.on_resource_create('Unknown Exemplar', {'name':'Unknown Exemplar'}, 'unknownExemplar')
	if !GameState.in_combat():
		originalOrganizerName = GameState.settings.get('rightOrganizerName')
		originalOrganizerData = GameState.get_organizer_data(originalOrganizerName)
		if sourceData:
			#GameState.change_right_organizer(sourceData.get_organizer_name())
			GameState.load_char_organizer(sourceData.get_organizer_name())
	initTrainingTab()
	call_deferred('initStatsTab')
	find_node('TabContainer').current_tab = GameState.settings.get('curExemplarTab', 0)
	Event.connect('training_queues_updated', self, 'on_training_queues_updated')
	Event.emit_signal('open_char_status')

func on_training_queues_updated():
	initTrainingTab()
	initStatsTab()

func initTrainingTab():
	initTrainingOptions()
	initTrainingOrganizer()
	initTrainingStatsChange()
	initStatusBars()
	
func initStatusBars():
	exemplarStatus.exemplarData = sourceData
	exemplarStatus.update_bar_sizes()

func initTrainingOptions():
	trainingOptions = []
	trainingMethodSelect.clear()
	trainingMethodSelect.add_item("-- Select Training Method --", 0)
	load_training_options_from_location()
	load_training_options_from_exemplar()
	countSelect.clear()
	for i in 5:
		countSelect.add_item("x"+str(i+1))
	trainingMethodSelect.select(selectedTrainingOption)
	countSelect.select(selectedCountOption)
	repeatTrainingButton.pressed = selectedRepeatOption
	addToPlanButton.disabled = selectedTrainingOption == 0
	update_training_method_description(selectedTrainingOption)
	update_pulsers()

func update_pulsers():
	if !shouldPulse: 
		Util.stop_pulsing(trainingMethodSelect)
		Util.stop_pulsing(addToPlanButton)
		return
		
	if trainingMethodSelect.selected == 0 and trainingOptions.size() > 0:
		Util.start_pulsing(trainingMethodSelect)
		Util.stop_pulsing(addToPlanButton)
	elif trainingMethodSelect.selected > 0:
		Util.start_pulsing(addToPlanButton)
		Util.stop_pulsing(trainingMethodSelect)
	else:
		Util.stop_pulsing(trainingMethodSelect)
		Util.stop_pulsing(addToPlanButton)

func load_training_options_from_exemplar():
	for entry in sourceData.get_organizer_data().get_entries_with_type('training'):
		var entryPath = entry.get('path', [])
		if entryPath.size() > 0 and entryPath[0] == 'Training Techniques':
			append_training_options(trainingOptions, entry, sourceData.get_organizer_name())
	return trainingOptions
	
func load_training_options_from_location():
	if !originalOrganizerName: 
		return {}
	var locationOrgName = originalOrganizerName
	var locationOrgData = GameState.get_organizer_data(locationOrgName)
	for entry in locationOrgData.get_entries_with_type('training'):
		append_training_options(trainingOptions, entry, locationOrgName)
	return trainingOptions
	
func append_training_options(trainingOptions, entry, orgName):
	if entry.data is TrainingData:
		entry.data.src = orgName
		trainingOptions.append(entry.data)
	else:
		var trainingDataList = entry.data['train']
		if trainingDataList is Dictionary: 
			trainingDataList = [trainingDataList]
		for trainingDataJson in trainingDataList:
			var trainingData = load('res://exemplar/TrainingData.gd').new()
			trainingData.deserialize(trainingDataJson)
			trainingMethodSelect.add_item(trainingData.description)
			trainingData.src = orgName
			trainingOptions.append(trainingData)

func initTrainingOrganizer():
	if sourceData:
		trainingOrganizerData = ExemplarData.get_training_organizer(sourceData)
		trainingOrganizerData.friendlyName = sourceData.entityName+"'s Training Plan"
		find_node('TrainingOrganizer').refresh_organizer_data(trainingOrganizerData)

func add_header(grid, text):
	var l = Label.new()
	l.text = text
	l.align = HALIGN_CENTER
	l.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_child(l)

func initTrainingStatsChange():
	var grid = find_node('StatsChangeHistory')
	Util.clear_children(grid)
	add_header(grid, 'Stat')
	add_header(grid, 'Today')
	add_header(grid, 'Since yesterday')
	add_header(grid, 'Since last week')
	
	var today = sourceData.stats
	var yesterday = sourceData.get_stats_change_over_time(1)
	var lastWeek = sourceData.get_stats_change_over_time(7)
	var allChangedKeys = {}
	for k in yesterday:
		allChangedKeys[k] = true
	for k in lastWeek: 
		allChangedKeys[k] = true
	allChangedKeys = allChangedKeys.keys()
	allChangedKeys.sort()
	if allChangedKeys.size() == 0:
		var label = Label.new()
		label.text = '(no recent changes)'
		grid.add_child(label)
	for k in allChangedKeys:
		var label = Label.new()
		label.text = Util.get_stat_friendly_name(k)
		label.hint_tooltip = Util.get_stat_description(k)
		label.mouse_filter = MOUSE_FILTER_PASS
		grid.add_child(label)
		
		label = Label.new()
		label.text = "%.1f"%(round(today.get(k, 0)*10)/10)
		label.align = HALIGN_CENTER
		grid.add_child(label)
		
		label = Label.new()
		if yesterday.get(k,0) > 0: yesterday[k] = "+%.1f"%(round(yesterday[k]*10)/10)
		elif yesterday.get(k,0) < 0: yesterday[k] = "%.1f"%(round(yesterday[k]*10)/10)
		else: yesterday[k] = ''
		label.text = str(yesterday.get(k,''))
		label.align = HALIGN_CENTER
		grid.add_child(label)
		
		label = Label.new()
		if lastWeek.get(k,0) > 0: lastWeek[k] = "%.1f"%(round(lastWeek[k]*10)/10)
		elif lastWeek.get(k,0) < 0: lastWeek[k] = "%.1f"%(round(lastWeek[k]*10)/10)
		else: lastWeek[k] = ''
		label.text = str(lastWeek.get(k, ''))
		label.align = HALIGN_CENTER
		grid.add_child(label)


func initStatsTab():
	if sourceData:
		update_label('ExemplarName', sourceData.entityName)
		update_label('PowerLevelLabel', "Power Level: "+str(round(sourceData.get_stats_summary('')['mean']*10)/10))
		update_label('StrLabel', "Strength: "+str(round(sourceData.get_stats_summary('str')['mean']*10)/10))
		update_label('AgiLabel', "Agility: "+str(round(sourceData.get_stats_summary('agi')['mean']*10)/10))
		update_label('MindLabel', "Mind: "+str(round(sourceData.get_stats_summary('int')['mean']*10)/10))
		update_label('WillLabel', "Spirit: "+str(round(sourceData.get_stats_summary('will')['mean']*10)/10))
		var grid = find_node('StrStats')
		Util.clear_children(grid)
		add_stats(grid, 'str.bone')
		add_stats(grid, 'str.bone.armBoneStr')
		add_stats(grid, 'str.bone.legBoneStr')
		add_stats(grid, 'str.bone.coreBoneStr')
		add_stats(grid, 'str.bone.skullBoneStr')
		add_stats(grid, 'str.muscle')
		add_stats(grid, 'str.muscle.armStr')
		add_stats(grid, 'str.muscle.legStr')
		add_stats(grid, 'str.muscle.coreStr')
		add_stats(grid, 'str.muscle.gripStr')
		add_stats(grid, 'str.endurance')
		add_stats(grid, 'str.endurance.armEnd')
		add_stats(grid, 'str.endurance.legEnd')
		add_stats(grid, 'str.endurance.coreEnd')
		add_stats(grid, 'str.endurance.gripEnd')
		add_stats(grid, 'str.b_recover')
		add_stats(grid, 'str.b_recover.healthRecover')
		add_stats(grid, 'str.b_recover.fatigueRecover')
		
		grid = find_node('AgiStats')
		Util.clear_children(grid)
		add_stats(grid, 'agi.speed')
		add_stats(grid, 'agi.speed.attackSpd')
		add_stats(grid, 'agi.speed.moveSpd')
		add_stats(grid, 'agi.speed.reactSpd')
		add_stats(grid, 'agi.dexterity')
		add_stats(grid, 'agi.dexterity.attackAgi')
		add_stats(grid, 'agi.dexterity.defendAgi')
		add_stats(grid, 'agi.dexterity.jumpAgi')
		add_stats(grid, 'agi.dexterity.balance')
		add_stats(grid, 'agi.dexterity.balanceRecover')
		
		grid = find_node('IntStats')
		Util.clear_children(grid)
		add_stats(grid, 'int.ability')
		add_stats(grid, 'int.ability.insight')
		add_stats(grid, 'int.ability.perceive')
		add_stats(grid, 'int.ability.synthesis')
		add_stats(grid, 'int.m_sharpness')
		add_stats(grid, 'int.m_sharpness.thinkSpeed')
		add_stats(grid, 'int.m_sharpness.focus')
		add_stats(grid, 'int.m_sharpness.multitask')
		add_stats(grid, 'int.skill')
		add_stats(grid, 'int.skill.emotionalInt')
		add_stats(grid, 'int.skill.languageInt')
		add_stats(grid, 'int.skill.musicInt')
		add_stats(grid, 'int.skill.mathInt')
		add_stats(grid, 'int.skill.spatialInt')
		add_stats(grid, 'int.m_recover')
		add_stats(grid, 'int.m_recover.focusRecovery')
		
		grid = find_node('WillStats')
		Util.clear_children(grid)
		add_stats(grid, 'will.mind')
		add_stats(grid, 'will.mind.emptyMind')
		add_stats(grid, 'will.mind.resistManipulation')
		add_stats(grid, 'will.mind.resistConfusion')
		add_stats(grid, 'will.body')
		add_stats(grid, 'will.body.resistFatigue')
		add_stats(grid, 'will.body.resistDisorient')
		add_stats(grid, 'will.soul')
		add_stats(grid, 'will.soul.determination')
		add_stats(grid, 'will.soul.spiritRecover')
		add_stats(grid, 'will.soul.resistDomination')
		
	if get_parent() is Control:
		self.rect_global_position = get_parent().rect_global_position
		self.rect_size = get_parent().rect_size
	elif get_parent() is Viewport:
		self.rect_size = get_parent().size/3*2
		self.rect_position = get_parent().size/6

func on_close():
	#GameState.set_char_organizer_visible(false)
	GameState.save_char_organizer()
	trainingOrganizer.save()
	if GameState.in_combat():
		GameState.set_char_organizer_visible(false)
	Event.emit_signal('close_char_status')

func add_stats(grid, statName):
	var chunks = statName.split('.', false)
	var depth = chunks.size() - 1
	var prefix = ''
	for i in depth: 
		prefix = prefix + '     '
	var c = Color.white
	match depth:
		1: c = Color.white
		2: c = Color.darkgray
		3: c = Color.black
	var label = Label.new()
	label.text = prefix+Util.get_stat_friendly_name(chunks[-1])+'    '
	label.modulate = c
	label.hint_tooltip = Util.get_stat_description(chunks[-1])
	label.mouse_filter = MOUSE_FILTER_STOP
	grid.add_child(label)
	label = Label.new()
	label.modulate = c
	label.align = HALIGN_RIGHT
	label.text = "%.1f"%[round(sourceData.get_stats_summary(statName)['mean']*10)/10]
	grid.add_child(label)

func _on_CloseButton_pressed():
	on_close()
	queue_free()

func _on_AddToPlanButton_pressed():
	shouldPulse = false
	trainingOrganizerData = trainingOrganizer.serialize() # Get any changes made to ordering or deletion
	GameState.add_organizer(trainingOrganizer.organizerDataName, trainingOrganizerData)
	var trainingData = trainingOptions[trainingMethodSelect.get_selected_id() - 1]
	var count = countSelect.get_selected_id()+1
	var repeat = repeatTrainingButton.pressed
	var repeatStr = ""
	if repeat: 
		repeatStr = " (repeat)"
#func add_entry(path:String, data, id=null, folderId=null, entrySceneName:String='OrganizerEntry', position=-1):
	var entryName = "%s: %s%s x%d"%[originalOrganizerData.friendlyName, trainingData.description, repeatStr, count]
	var saveData = {"loc":originalOrganizerName, "src":trainingData.src, "id":trainingData.id, "count": count, "repeat":repeat}
	trainingOrganizerData.add_entry(entryName+'^noEdit', saveData)
	trainingOrganizer.refresh_organizer_data(trainingOrganizerData)
	var trainingItems = trainingOrganizer.entryContainer.get_children()
	if trainingItems.size() > 0:
		Util.start_pulsing(trainingItems[trainingItems.size()-1], 4, 0.2)
		Util.blink_once(trainingOrganizer)
	countSelect.select(0)
	Event.emit_signal("training_added", sourceData, trainingData, count, repeat, entryName)
	update_pulsers()

func _on_TrainingMethodSelect_item_selected(index):
	shouldPulse = true
	selectedTrainingOption = index
	addToPlanButton.disabled = index == 0
	update_training_method_description(index)
	update_pulsers()

func update_training_method_description(index):
	var text
	index -= 1
	if trainingOptions.size() == 0: 
		text = ""
		trainingMethodSelect.disabled = true
		countSelect.disabled = true
		repeatTrainingButton.disabled = true
		addToPlanButton.disabled = true
	else:
		if index < 0:
			text = ""
		else:
			var selectedTraining = trainingOptions[index]
			text = "%s\n%s"%[selectedTraining.description, selectedTraining.get_summary()]
	find_node('SelectedTrainingDesc').text = text


func _on_CountSelect_item_selected(index):
	selectedCountOption = index


func _on_RepeatTraining_toggled(button_pressed):
	selectedRepeatOption = button_pressed


func _on_TabContainer_tab_changed(tab):
	GameState.settings['curExemplarTab'] = tab
