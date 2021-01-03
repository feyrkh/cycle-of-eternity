extends TextureRect
class_name TargetLineFocus

const rotate_speed = 10
const DEFAULT_ALPHA = 0.4
const HIGHLIGHT_ALPHA = 0.8
const OFFSET_RADIANS = deg2rad(7)

var combatScene
var owningCombatant # the Combatant this is attached to
var radialOffset # when idle, how many radians to offset your position to accomodate other foci
var targetCombatant setget set_target_combatant # the Combatant this is focused on, if any
var idleVector:Vector2
var rotateCounter = 0
var targetLine

var dupe

func _ready():
	idleVector = Vector2(owningCombatant.radius+rect_size.x/2, 0)
	modulate = owningCombatant.color
	modulate.a = 0.3

func is_target_line_focus(): return true

func _process(delta):
	if dupe:
		dupe.rect_global_position = get_global_mouse_position()
	if !owningCombatant.pauseTargets:
		rotateCounter += delta
	if targetLine:
		self.rect_position = targetLine.points[targetLine.points.size()-1]-rect_size/2
	elif !targetCombatant:
		var rot = lerp(0, 2*PI, fmod(rotateCounter, rotate_speed)/rotate_speed) + radialOffset
		self.rect_position = idleVector.rotated(rot) + owningCombatant.rect_position - rect_size/2

func set_target_combatant(newTarget):
	if !newTarget or !newTarget.has_method('is_combatant'):
		clear_target()
		targetCombatant = null
	elif newTarget == owningCombatant:
		return # targeting yourself?!
	elif newTarget == targetCombatant:
		return # targeting the same person again
	else:
		clear_target()
		targetCombatant = null
		targetCombatant = newTarget
		targetLine = load("res://combat/TargetLine.tscn").instance()
		targetLine.sourceNode = owningCombatant
		targetLine.targetNode = newTarget
		targetLine.default_color = owningCombatant.color
		targetLine.offsetRadians = OFFSET_RADIANS * ((owningCombatant.get_targets_on(newTarget).size()*2.2)+1)
		combatScene.lineLayer.add_child(targetLine)

func clear_target():
	if targetLine:
		targetLine.cleanup()
		targetLine.queue_free()

func get_drag_data(pos):
#	var icon = TextureRect.new()
#	icon.texture = load('res://img/combat/combat_token.png')
	var icon = Control.new()
	if dupe:
		dupe.queu
	dupe = duplicate(0)
	dupe.rect_position = Vector2.ZERO
	#dupe.rect_position = dupe.get_global_rect().position - get_global_mouse_position()
	dupe.modulate.a = 0.3
	icon.add_child(dupe) #load('res://combat/CombatantPreview.tscn').instance()
	set_drag_preview(icon)
	return self

func can_drop_data(pos, data): 
	if data.has_method('is_combatant') or data.has_method('is_target_line_focus'):
		return true
	return false

func drop_data(pos, data):
	if data.has_method('is_combatant'):
		data.rect_position = pos + self.rect_position
		Event.emit_signal("update_target_lines")
	elif data.has_method('is_target_line_focus'):
		data.targetCombatant = self.targetCombatant

func _on_TargetLineFocus_mouse_entered():
	modulate.a = HIGHLIGHT_ALPHA
	if targetCombatant == null:
		owningCombatant.pauseTargets = true

func _on_TargetLineFocus_mouse_exited():
	modulate.a = DEFAULT_ALPHA
	if targetCombatant == null:
		owningCombatant.pauseTargets = false


