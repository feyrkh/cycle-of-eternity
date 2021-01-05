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

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
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
	
	rightOrganizerData.add_entry("Jab^noDelete", {
		"cmd": "combatTech", "attack": [
			{"t":AttackTechnique.PREPARE, "l": 0.1}, # quick preparation
			{"t":AttackTechnique.PARRY, "l": 0.01}, # quick parry at the start of the strike
			{"t":AttackTechnique.STRIKE, "l": 0.05}, # quick attack at the end
		]
	})
	
	rightOrganizerData.add_entry("Punch^noDelete", {
		"cmd": "combatTech", "attack": [
			{"t":AttackTechnique.PREPARE, "l": 0.1}, 
			{"t":AttackTechnique.CHARGE, "l": 0.01},
			{"t":AttackTechnique.STRIKE, "l": 0.05}, 
		]
	})
	
	UI.rightOrganizer.refresh_organizer_data(rightOrganizerData)
	Event.emit_signal("entering_combat", self)

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
	tech.segments = data.get('attack', [])
	techniqueLayer.add_child(tech)

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
