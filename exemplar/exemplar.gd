extends Control

var sourceData
var orgEntryNode
var originalOrganizer

func update_label(labelName, newText):
	var label = find_node(labelName)
	if !label:
		printerr("Could not find label=%s, wanted to update it to '%s'"%[labelName, newText])
		return
	label.text = str(newText)

func _ready():
	originalOrganizer = GameState.settings.get('rightOrganizerName')
	if sourceData:
		GameState.change_right_organizer(sourceData.get_organizer_name())
		update_label('ExemplarName', sourceData.entityName)
		update_label('PowerLevelLabel', "Power Level: "+str(round(sourceData.get_stats_summary('')['mean']*10)/10))
		var grid = find_node('StrStats')
		add_stats(grid, 'str')
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
		add_stats(grid, 'agi')
		add_stats(grid, 'agi.speed')
		add_stats(grid, 'agi.speed.attackSpd')
		add_stats(grid, 'agi.speed.moveSpd')
		add_stats(grid, 'agi.speed.reactSpd')
		add_stats(grid, 'agi.dexterity')
		add_stats(grid, 'agi.dexterity.attackAgi')
		add_stats(grid, 'agi.dexterity.defendAgi')
		add_stats(grid, 'agi.dexterity.jumpAgi')
		
		grid = find_node('IntStats')
		add_stats(grid, 'int')
		add_stats(grid, 'int.ability')
		add_stats(grid, 'int.ability.insight')
		add_stats(grid, 'int.ability.perceive')
		add_stats(grid, 'int.ability.synthesis')
		add_stats(grid, 'int.focus')
		add_stats(grid, 'int.focus.thinkSpeed')
		add_stats(grid, 'int.focus.multitask')
		add_stats(grid, 'int.skill')
		add_stats(grid, 'int.skill.emotionalInt')
		add_stats(grid, 'int.skill.languageInt')
		add_stats(grid, 'int.skill.musicInt')
		add_stats(grid, 'int.skill.mathInt')
		add_stats(grid, 'int.skill.spatialInt')
		add_stats(grid, 'int.m_recover')
		add_stats(grid, 'int.m_recover.focusRecovery')
		
		grid = find_node('WillStats')
		add_stats(grid, 'will')
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
	GameState.change_right_organizer(originalOrganizer)

func add_stats(grid, statName):
	var chunks = statName.split('.', false)
	var depth = chunks.size()
	var prefix = ''
	for i in depth: 
		prefix = prefix + '     '
	var label = Label.new()
	label.text = prefix+Util.get_stat_friendly_name(chunks[-1])+'    '
	grid.add_child(label)
	label = Label.new()
	label.align = HALIGN_RIGHT
	label.text = str(round(sourceData.get_stats_summary(statName)['mean']*10)/10)
	grid.add_child(label)


func _on_CloseButton_pressed():
	on_close()
	queue_free()
