extends LocationScene


var entityLayer
var lineLayer
var focusLayer
var techniqueLayer

var combatData
var exemplarDataList
var opponentDataList

var exemplarCombatants = []
var opponentCombatants = []
var selectedCombatant

var closestTargetLinePoint
var placingTechnique

var opponentCounts = {}
var inCharacterScreen

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	if !GameState.settings.get('combatEnabled'):
		GameState.settings['combatEnabled'] = true
		GameState.update_builtin_exemplar_commands()
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
			opponent.add_combat_line(exemplar)
			#exemplar.add_center_line(opponent)
	
	rightOrganizerName = 'combat'
	rightOrganizerData = OrganizerData.new()
	rightOrganizerData.name = 'combat'
	rightOrganizerData.friendlyName = 'Combat'
	rightOrganizerData.allowNewFolder = false
	rightOrganizerData.allowDelete = false
	
	UI.rightOrganizer.refresh_organizer_data(rightOrganizerData)
	Event.emit_signal("entering_combat", self)
	Event.connect('open_char_status', self, 'on_open_char_status')
	Event.connect('close_char_status', self, 'on_close_char_status')

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
				finish_placing_technique()
			elif event.button_index == BUTTON_RIGHT and event.pressed:
				cancel_placing_technique()
		elif inCharacterScreen:
			pass
		else:
			if event.button_index == BUTTON_RIGHT and event.pressed:
				if selectedCombatant: 
					set_selected_combatant(null)


func run_command(cmd, data:Dictionary, sourceNode:Node=null):
	match cmd:
		'combatTech': start_placing_technique(data, sourceNode) 
		_: printerr('Invalid command (at least in combat!): ', cmd, '; data=', data, '; sourceNode=', sourceNode.name)

func start_placing_technique(data, sourceNode):
	print("placing technique '"+sourceNode.label.text+": "+to_json(data))
	if placingTechnique:
		placingTechnique.queue_free()
		placingTechnique = null
	var tech = AttackTechnique.new()
	tech.deserialize(data)
	techniqueLayer.add_child(tech)
	placingTechnique = tech

func finish_placing_technique():
	if placingTechnique:
		if !placingTechnique.sourceCombatant or !placingTechnique.targetCombatant or !placingTechnique.targetLine:
			placingTechnique.queue_free()
			placingTechnique = null
			return
		placingTechnique.finish_placing()
		placingTechnique = null

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

# Check for any important quest states and setup as needed, if this returns true then set_default() will be skipped; may call setup_default() manually as well if needed
func setup_quest()->bool:
	match GameState.quest.get(Quest.Q_TUTORIAL, ''):
		_: return false


func _on_EntityLayer_mouse_entered():
	pass # Replace with function body.
