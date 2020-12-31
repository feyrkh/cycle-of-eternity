extends Control

var sourceData # type=ExemplarData
var orgEntryNode
var originalOrganizerName
var originalOrganizerData
var trainingOrganizerData

var trainingOptions = [] # transient, refreshed by load_training_options_from_location

onready var trainingMethodSelect:OptionButton = find_node('TrainingMethodSelect')
onready var repeatCountSelect:OptionButton = find_node('RepeatCountSelect')
onready var addToPlanButton = find_node("AddToPlanButton")
onready var trainingOrganizer = find_node("TrainingOrganizer")

func update_label(labelName, newText):
	var label = find_node(labelName)
	if !label:
		printerr("Could not find label=%s, wanted to update it to '%s'"%[labelName, newText])
		return
	label.text = str(newText)

func _ready():
	if !sourceData:
		sourceData = load('res://exemplar/ExemplarData.gd').new()
		sourceData.on_resource_create('Sample Exemplar', {'name':'Sample Exemplar'}, 'sampleExemplar')
	originalOrganizerName = GameState.settings.get('rightOrganizerName')
	originalOrganizerData = GameState.get_organizer_data(originalOrganizerName)
	if sourceData:
		GameState.change_right_organizer(sourceData.get_organizer_name())
	initTrainingTab()
	call_deferred('initStatsTab')

func initTrainingTab():
	initTrainingOptions()
	initTrainingOrganizer()
	initTrainingStatsChange()

func initTrainingOptions():
	var trainingOptionData = load_training_options_from_location()
	for i in 5:
		repeatCountSelect.add_item("Repeat x"+str(i+1))
	update_training_method_description(0)

func load_training_options_from_location():
	if !originalOrganizerName: return {}
	var locationOrgName = originalOrganizerName
	var locationOrgData = GameState.get_organizer_data(locationOrgName)
	trainingOptions = []
	for entry in locationOrgData.get_entries_with_type('training'):
		if entry.data is TrainingData:
			trainingOptions.append(entry.data)
		else:
			var trainingDataList = entry.data['train']
			if trainingDataList is Dictionary: 
				trainingDataList = [trainingDataList]
			for trainingDataJson in trainingDataList:
				var trainingData = load('res://exemplar/TrainingData.gd').new()
				trainingData.deserialize(trainingDataJson)
				trainingMethodSelect.add_item(trainingData.description)
				trainingOptions.append(trainingData)
	
	

func initTrainingOrganizer():
	if sourceData:
		trainingOrganizerData = GameState.get_organizer_data('train_plan_'+sourceData.entityId)
		trainingOrganizerData.friendlyName = sourceData.entityName+"'s Training Plan"
		find_node('TrainingOrganizer').refresh_organizer_data(trainingOrganizerData)

func initTrainingStatsChange():
	var grid = find_node('StatsChangeHistory')
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
		grid.add_child(label)
		
		label = Label.new()
		label.text = str(today.get(k, 0))
		label.align = HALIGN_CENTER
		grid.add_child(label)
		
		label = Label.new()
		if yesterday.get(k,0) > 0: yesterday[k] = '+'+str(yesterday[k])
		label.text = str(yesterday.get(k,''))
		label.align = HALIGN_CENTER
		grid.add_child(label)
		
		label = Label.new()
		if lastWeek.get(k,0) > 0: lastWeek[k] = '+'+str(lastWeek[k])
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
		add_stats(grid, 'str.endurance.fatigue')
		add_stats(grid, 'str.endurance.armEnd')
		add_stats(grid, 'str.endurance.legEnd')
		add_stats(grid, 'str.endurance.coreEnd')
		add_stats(grid, 'str.endurance.gripEnd')
		add_stats(grid, 'str.b_recover')
		add_stats(grid, 'str.b_recover.fatigueRecover')
		add_stats(grid, 'str.b_recover.woundRecover')
		
		grid = find_node('AgiStats')
		add_stats(grid, 'agi.speed')
		add_stats(grid, 'agi.speed.attackSpd')
		add_stats(grid, 'agi.speed.moveSpd')
		add_stats(grid, 'agi.speed.reactSpd')
		add_stats(grid, 'agi.dexterity')
		add_stats(grid, 'agi.dexterity.attackAgi')
		add_stats(grid, 'agi.dexterity.defendAgi')
		add_stats(grid, 'agi.dexterity.jumpAgi')
		
		grid = find_node('IntStats')
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
		add_stats(grid, 'will.mind')
		add_stats(grid, 'will.mind.emptyMind')
		add_stats(grid, 'will.mind.focus')
		add_stats(grid, 'will.mind.resistManipulation')
		add_stats(grid, 'will.mind.resistConfusion')
		add_stats(grid, 'will.body')
		add_stats(grid, 'will.body.resistFatigue')
		add_stats(grid, 'will.body.resistDisorient')
		add_stats(grid, 'will.soul')
		add_stats(grid, 'will.soul.determination')
		add_stats(grid, 'will.soul.spiritFatigue')
		add_stats(grid, 'will.soul.spiritRecover')
		add_stats(grid, 'will.soul.resistDomination')
		
	if get_parent() is Control:
		self.rect_global_position = get_parent().rect_global_position
		self.rect_size = get_parent().rect_size
	elif get_parent() is Viewport:
		self.rect_size = get_parent().size/3*2
		self.rect_position = get_parent().size/6

func on_close():
	GameState.change_right_organizer(originalOrganizerName)
	GameState.add_organizer(trainingOrganizer.organizerDataName, trainingOrganizer.save())

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
	trainingOrganizerData = trainingOrganizer.save() # Get any changes made to ordering or deletion
	GameState.add_organizer(trainingOrganizer.organizerDataName, trainingOrganizerData)
	var trainingData = trainingOptions[trainingMethodSelect.get_selected_id()]
	var repeatCount = repeatCountSelect.get_selected_id()+1
#func add_entry(path:String, data, id=null, folderId=null, entrySceneName:String='OrganizerEntry', position=-1):
	var entryName = "%s: %s x%d"%[originalOrganizerData.friendlyName, trainingData.description, repeatCount]
	var saveData = {"loc":originalOrganizerName, "type":trainingData.name, "repeat": repeatCount}
	trainingOrganizerData.add_entry(entryName+'^noEdit', saveData)
	trainingOrganizer.refresh_organizer_data(trainingOrganizerData)

func _on_TrainingMethodSelect_item_selected(index):
	update_training_method_description(index)

func update_training_method_description(index):
	var text
	if trainingOptions.size() == 0: 
		text = ""
		trainingMethodSelect.disabled = true
		repeatCountSelect.disabled = true
		addToPlanButton.disabled = true
	else:
		var selectedTraining = trainingOptions[index]
		text = "%s\n%s"%[selectedTraining.description, selectedTraining.get_summary()]
	find_node('SelectedTrainingDesc').text = text
