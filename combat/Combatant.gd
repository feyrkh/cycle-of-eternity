extends Control
class_name Combatant

var BONUS_TARGET_ICON_INTERVAL = 75

var combatScene
var entityData
var color:Color
var radius = 50
var organizerName

var targetIcons = [] # rotating icons the player can drag to target different opponents
var pauseTargets = false # pause target rotation when the player is using them

const playfieldPath = "../../PlayField"

onready var entityNameLabel = find_node('EntityName')
onready var centerX = entityNameLabel.rect_position.x + entityNameLabel.rect_size.x/2 
onready var iconSelect = find_node('IconSelected')

func _ready():
	if !entityData: 
		entityData = {}
	if entityData is String:
		if !entityData.begins_with('res://'):
			entityData = 'res://data/opponent/'+entityData
		if !entityData.ends_with('.json'):
			entityData = entityData+'.json'
		entityData = Util.load_json_file(entityData)
	
	if entityData is ExemplarData:
		setup_exemplar()
	else:
		setup_opponent()
	Event.connect('chakraZoom', self, 'on_zoom')

func get_attack_speed():
	return max(1, entityData.get('attackSpd', 50))

func get_defense_speed():
	return max(1, entityData.get("reactSpd", 50))

func add_center_line(target):
	var centerLine = Line2D.new()
	centerLine.points = [rect_position, lerp(rect_position, target.rect_position, 0.5), target.rect_position]
	centerLine.width = 1
	centerLine.default_color = Color(0.2, 0, 0)
	combatScene.lineLayer.add_child(centerLine)

func add_combat_line(target):
	var targetLine = load('res://combat/TargetLine.tscn').instance()
	targetLine.sourceCombatant = self
	targetLine.targetCombatant = target
	targetLine.default_color = color
	combatScene.lineLayer.add_child(targetLine)
	targetLine.update_attack_line()
	return targetLine

func setup_exemplar():
	color = Color.aquamarine
	entityNameLabel.rect_position.y -= entityNameLabel.rect_size.y + radius*2
	find_node('IconBackground').modulate = color
	find_node('EntityName').text = entityData.entityName
	setup_combat_icon("res://img/people/secretary.png")
	setup_target_icons()
	organizerName = entityData.get_organizer_name()

func setup_target_icons():
	var numIcons = 0
	var interval = BONUS_TARGET_ICON_INTERVAL
	var multitasking = entityData.get_stat('multitask')
	if multitasking < 1: multitasking = 1
	while multitasking > 0:
		numIcons += 1
		multitasking -= interval
		interval += BONUS_TARGET_ICON_INTERVAL
	var radialOffset = deg2rad(360/numIcons)
	var curOffset = 0
	for i in numIcons:
		var newIcon = load("res://combat/TargetLineFocus.tscn").instance()
		newIcon.owningCombatant = self
		newIcon.radialOffset = curOffset
		newIcon.combatScene = combatScene
		curOffset += radialOffset
		combatScene.focusLayer.add_child(newIcon)
		targetIcons.append(newIcon)
	
func setup_opponent():
	color = Color.salmon
	find_node('IconBackground').modulate = color
	find_node('EntityName').text = entityData.get('entityName', "Unknown opponent")
	setup_combat_icon(entityData.get('combatIcon'))

func setup_combat_icon(textureName):
	if textureName: 
		var icon:TextureRect = find_node('Icon')
		icon.texture = load(textureName)
		var scaleX = 80/icon.texture.get_size().x
		var scaleY = 80/icon.texture.get_size().y
		var newScale = min(scaleX, scaleY)
		icon.rect_scale = Vector2(newScale, newScale)
		icon.rect_position = Vector2(radius-(icon.rect_size.x*newScale/2), radius-(icon.rect_size.y*newScale/2))

func get_targets_on(opponent):
	var result = []
	for targetIcon in targetIcons:
		if targetIcon.targetCombatant == opponent:
			result.append(targetIcon)
	return result

func get_next_offset_slot(opponent):
	var existingTargets = get_targets_on(opponent)
	var slotsTaken = {}
	for target in existingTargets:
		slotsTaken[target.offsetSlot] = true
	var firstOpenSlot = 0
	while slotsTaken.get(firstOpenSlot): 
		firstOpenSlot += 1
	return firstOpenSlot

func can_drop_data(pos, data): 
	if data == self or data is TargetLineFocus:
		return true
	return false

func drop_data(pos, data):
	if data is TargetLineFocus:
		data.targetCombatant = self
	elif data == self:
		data.rect_position = pos + self.rect_position
		Event.emit_signal("update_target_lines")

func is_combatant(): return true

func on_zoom(zoom):
	entityNameLabel.rect_scale = zoom
	entityNameLabel.rect_position.x = centerX - (entityNameLabel.rect_size.x/2 * zoom.x)

func _on_Combatant_gui_input(event):
	# pass through to the PlayField
	get_node(playfieldPath)._on_PlayField_gui_input(event)


func _on_Control_gui_input(event):
	if event is InputEventMouseButton:
		if !combatScene.can_select_combatant(): 
			return
		if event.button_index == BUTTON_LEFT and event.pressed and GameState.settings.get('combatSelectOk'):
			combatScene.set_selected_combatant(self)

func select():
	if GameState.settings.get('combatSelectOk'):
		iconSelect.visible = true
		GameState.change_right_organizer(organizerName)
		if entityData is ExemplarData:
			Event.emit_signal("exemplar_combatant_selected", self)
		else:
			Event.emit_signal("opponent_combatant_selected", self)
	
func deselect():
	iconSelect.visible = false
