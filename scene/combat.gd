extends LocationScene

signal attack_technique_selected(tech)
signal block_technique_selected(tech)
signal attack_technique_placed(tech)
signal block_technique_placed(tech)

var entityLayer
var lineLayer:Control
var focusLayer
var techniqueLayer

var combatData
var exemplarDataList
var opponentDataList
var combatType # spar, normal, boss

var exemplarCombatants = []
var opponentCombatants = []
var selectedCombatant

var closestTargetLinePoint
var placingTechnique
var placingSource

var opponentCounts = {}
var inCharacterScreen

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	if !GameState.settings.get('combatEnabled'):
		GameState.settings['combatEnabled'] = true
		GameState.update_builtin_exemplar_commands()
	combatType = combatData.get('combatType', 'normal')
	opponentDataList = opponentDataList + opponentDataList
	opponentDataList = opponentDataList + opponentDataList
	#.setup_base() - skip base setup, this isn't really a location that needs equipment or organizers loaded
	entityLayer = find_node('EntityLayer', true, false)
	lineLayer = find_node('LineLayer', true, false)
	focusLayer = find_node('FocusLayer', true, false)
	techniqueLayer = find_node('TechniqueLayer', true, false)
	UI.enter_combat_mode()
	yield(get_tree(), "idle_frame")
	position_entities(exemplarCombatants, exemplarDataList, 0.1)
	position_entities(opponentCombatants, opponentDataList, 0.9)
	var opponentCount = 0
	for opponent in opponentCombatants:
		opponentCount += 1
		generate_opponent_organizer(opponent, opponentCount)
				
	for exemplar in exemplarCombatants:
		for opponent in opponentCombatants:
			pass
			#exemplar.add_combat_line(opponent)
			#opponent.add_combat_line(exemplar)
			#exemplar.add_center_line(opponent)
	
	rightOrganizerName = 'combat'
	rightOrganizerData = OrganizerData.new()
	rightOrganizerData.name = 'combat'
	rightOrganizerData.friendlyName = 'Combat'
	rightOrganizerData.allowNewFolder = false
	rightOrganizerData.allowDelete = false
	if combatType == 'spar':
		rightOrganizerData.add_entry('Leave combat', {'cmd':'exitCombat', 'combat':true}, 'exitCombat')
	
	GameState.update_builtin_exemplar_commands()
	UI.rightOrganizer.refresh_organizer_data(rightOrganizerData)
	Event.emit_signal("entering_combat", self)
	Event.connect('open_char_status', self, 'on_open_char_status')
	Event.connect('close_char_status', self, 'on_close_char_status')

func setup_quest():
	GameState.update_builtin_exemplar_commands()
	yield(get_tree(), "idle_frame")
	if GameState.get_quest_status(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_SPAR_ATTACK and !GameState.get_quest_status(Quest.Q_COMBAT_A):
		GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_ACTIVE)
	var combatAttackState = GameState.get_quest_status(Quest.Q_COMBAT_A)
	if combatAttackState:
		match combatAttackState:
			Quest.Q_COMBAT_A_ACTIVE: quest_move_combatants()

func on_open_char_status():
	inCharacterScreen = true

func on_close_char_status():
	inCharacterScreen = false

func generate_opponent_organizer(opponent, opponentNum):
	var organizerData = OrganizerData.new()
	var organizerName = '__opponent_'+str(opponentNum)
	opponent.organizerName = organizerName
	organizerData.friendlyName = opponent.entityData.get('entityName', 'Unknown opponent')+' '+str(opponentNum)
	organizerData.allowNewFolder = false
	organizerData.allowDelete = false
	GameState._organizers[organizerName] = organizerData

func _process(delta):
	var closestPoints = get_tree().get_nodes_in_group("closestPoint")
	var distSq = Util.MAX_INT
	var mousePos = get_global_mouse_position()
	for point in closestPoints:
		point.visible = false
		var curDist = mousePos.distance_squared_to(point.global_position)
		if curDist < distSq:
			distSq = curDist
			closestTargetLinePoint = point
	if closestTargetLinePoint: 
		closestTargetLinePoint.visible = true

func _input(event):
	if event is InputEventMouseButton:
		if placingTechnique:
			if event.button_index == BUTTON_LEFT and event.pressed:
				if finish_placing_technique(): get_tree().set_input_as_handled()
			elif event.button_index == BUTTON_RIGHT and event.pressed:
				cancel_placing_technique()
				get_tree().set_input_as_handled()
		elif inCharacterScreen:
			pass
		else:
			if event.button_index == BUTTON_RIGHT and event.pressed:
				if selectedCombatant: 
					set_selected_combatant(null)
					get_tree().set_input_as_handled()


func run_command(cmd, data:Dictionary, sourceNode:Node=null):
	match cmd:
		'combatTech': start_placing_technique(data, sourceNode) 
		'exitCombat': exit_combat()
		_: printerr('Invalid command (at least in combat!): ', cmd, '; data=', data, '; sourceNode=', sourceNode.name)

func exit_combat():
	var postCombatSceneData = combatData.get('postCombatScene', {'sceneName':'office', 'sceneSettings':{'cmd':'scene', 'scene':'office', 'organizerName':'office'}})
	GameState.loadScene(postCombatSceneData.get('sceneName'), postCombatSceneData.get('sceneSettings'))
	if GameState.get_quest_status(Quest.Q_COMBAT_A) and GameState.get_quest_status(Quest.Q_COMBAT_A) != Quest.Q_COMPLETE:
		GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMPLETE)

func start_placing_technique(data, sourceNode):
	#print("placing technique '"+sourceNode.label.text+": "+to_json(data))
	if placingTechnique:
		placingTechnique.queue_free()
		placingTechnique = null
	#placingSource = sourceNode
	var tech = preload('res://combat/AttackTechnique.tscn').instance()
	#data['techName'] = sourceNode.label.text
	tech.combatScene = self
	tech.deserialize(data)
	techniqueLayer.add_child(tech)
	placingTechnique = tech
	if tech.isAttack:
		emit_signal("attack_technique_selected", tech)
	if tech.isBlock:
		emit_signal("block_technique_selected", tech)

func finish_placing_technique():
	if placingTechnique and placingTechnique.targetLine:
		if !placingTechnique.sourceCombatant or !placingTechnique.targetCombatant or !placingTechnique.targetLine:
			placingTechnique.queue_free()
			placingTechnique = null
			return false
		var newCopy = placingTechnique.data
		#placingTechnique.get_parent().remove_child(placingTechnique)
		#techniqueLayer.add_child(placingTechnique)
		placingTechnique.finish_placing()
		if placingTechnique.isAttack:
			emit_signal("attack_technique_placed", placingTechnique)
		if placingTechnique.isBlock:
			emit_signal("block_technique_placed", placingTechnique)
		placingTechnique = null
		start_placing_technique(newCopy, placingSource)
		return true
	else:
		return false

func cancel_placing_technique():
	if placingTechnique:
		placingTechnique.queue_free()
		placingTechnique = null

func set_selected_combatant(combatant):
	if combatant and selectedCombatant == combatant: return
	if selectedCombatant:
		selectedCombatant.deselect()
	selectedCombatant = combatant
	if selectedCombatant:
		selectedCombatant.select()
	else:
		GameState.change_right_organizer('combat')

func can_select_combatant():
	return placingTechnique == null

func shutdown_scene():
	UI.leave_combat_mode()
	Event.emit_signal("leaving_combat", self)
		
func startup_scene(combatData):
	self.combatData = combatData
	self.exemplarDataList = combatData.get('exemplarData', [])
	self.opponentDataList = combatData.get('opponentData', [])
	if !(opponentDataList is Array):
		opponentDataList = [opponentDataList]

func position_entities(combatantsList, entityDataList, linePosition):
	var yOffset = UI.dragSurface.rect_size.y * linePosition # randi()%int(UI.dragSurface.rect_size.y) #
	var xOffset = UI.dragSurface.rect_size.x/(entityDataList.size()+1)
	var x = xOffset
	for entityData in entityDataList:
		var combatant = load("res://combat/Combatant.tscn").instance()
		combatant.combatScene = self
		combatant.entityData = entityData
		entityLayer.add_child(combatant)
		combatant.rect_position = Vector2(x, yOffset)
		x += xOffset
		combatantsList.append(combatant)
		
# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

func quest_move_combatants():
	find_node("FocusLayer").visible = false
	GameState.settings['combatSelectOk'] = false
	UI.rightOrganizer.get_entry_by_id('exitCombat').visible = false
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_MOVE_COMBATANT)
	Conversation.clear()
	Conversation.text("Welcome to combat. This is an abstract representation of a battle, with your allies at the top and enemies at the bottom.\nClick and drag one of the combatants to move them.")
	yield(Conversation.run(), "completed")
	yield(Event,"update_target_lines")
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_FOCUS_TARGET)
	Conversation.clear()
	Conversation.text("Good. Position doesn't affect any outcomes, but it can help you observe the fight better. Now take a look at the target icon floating around your exemplar.\nIf you are exceptionally skilled you may have two targets, but most exemplars have only one. Click and drag a target onto one of the practice dummies.")
	Conversation.run()
	find_node("FocusLayer").visible = true
	while lineLayer.get_child_count() == 0:
		yield(Event,"update_target_lines")
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_SELECT_EXEMPLAR)
	Conversation.clear()
	Conversation.text("This represents your ability to bring the attack to the enemy. This line is a timeline of attack and response - your attacks will start from your exemplar's icon and travel down the line toward the enemy.\nEnemy responses, if any, will travel up the line to meet your attacks.\nWhen your attacks reach the midpoint they will strike the enemy, or be blocked if the enemy times their response correctly.\nThe midpoint of the line varies depending on your attack speed relative to the enemy's response speed - if you are fast enough, you could potentially send multiple attacks their way before they can respond even once!\nNext, click on your exemplar to select them, and look for the list of combat techniques they know.")
	yield(Conversation.run(), "completed")
	GameState.settings['combatSelectOk'] = true
	yield(Event, "exemplar_combatant_selected")
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_SELECT_ATTACK)
	Conversation.clear()
	Conversation.text("Entries not related to combat are disabled. Combat techniques have icons for sword, shield, or both next to them.\nA sword means the technique can be placed on your attack line, a shield means it can be placed on an enemy's attack line.\nClick on an attack (Kick or Jab) - defensive skills are no use, since these training dummies will not target you.")
	Conversation.run()
	yield(self, "attack_technique_selected")
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_PLACE_ATTACK)
	Conversation.clear()
	Conversation.text("A representation of the technique appears near your mouse, and you can hover over your attack timeline to see it in context.\nYou can place it anywhere you like on your half of the timeline, but the closer to the midpoint you place it, the longer you will be 'unbalanced' after the move completes.\nYou could throw out a quick deflection to prevent damage at the last moment, but you may be vulnerable to multiple followup attacks if you do!\nPlace the technique on your timeline wherever you like.")
	Conversation.run()
	yield(self, "attack_technique_placed")
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_UNPAUSE)
	Conversation.clear()
	Conversation.text("You will notice that once you've placed a technique on the line, you can't place any other techniques ahead of it - techniques may only be added after the end of the last placed technique!\nUnpause the flow of time to see your attack play out - you can press the spacebar, or use the controls at the bottom right.")
	Conversation.run()
	yield(Event,"combat_speed_multiplier")
	var speed = Calendar.combatSpeed
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMBAT_A_EXIT_COMBAT)
	Conversation.clear()
	Conversation.text("The different colored sections of a technique represent different phases of the attack - preparing, charging, striking, blocking, deflecting, grappling, or unbalanced penalties.\nWe'll learn more about the details later. For now, either proceed to destroy all of the practice dummies or right-click to deselect any combatants and use the 'Leave combat' item to return to the training hall.")	
	yield(Conversation.run(), "completed")
	Calendar.update_combat_speed(speed) # conversation automatically pauses, so we have to unpause or it feels weird since we just told them to start time up
	GameState.set_quest_status(Quest.Q_COMBAT_A, Quest.Q_COMPLETE)
	GameState.set_quest_status(Quest.Q_TUTORIAL, Quest.Q_TUTORIAL_SPAR_DEFEND)
	set_selected_combatant(null)
	var exitBtn = UI.rightOrganizer.get_entry_by_id('exitCombat')
	if exitBtn: 
		exitBtn.visible = true
		UI.call_attention_from_left('exitCombat')


func _on_ClickPlayField_pressed():
	if can_select_combatant(): set_selected_combatant(null)
