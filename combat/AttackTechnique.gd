extends Node2D
class_name AttackTechnique

# dodge: mitigates damage at the time of the hit
# block: reduces the effectivness
# deflect: interrupts windups, 

const EMPTY = "" # no interrupt possible, other techniques can fit inside
const PREPARE = "prep" # interruption by an attack
const CHARGE = "charge" # store charge to be released by a strike
const STRIKE = "strike" # do damage, multiply by stored charge
const DEFLECT = "deflect" # interrupts another attack that is striking when it hits
const OFF_BALANCE = "idle"
const BLOCK = "block" # directly opposes strikes, does not affect charge
const INTERRUPT = "interrupt" # interrupts charging, blocking
const DISTRACT = "distract" # reduce aggro on this timeline
const TAUNT = "taunt" # increase aggro on this timeline

const LINE_COLORS = {EMPTY:Color.transparent, PREPARE:Color.white, CHARGE:Color.darkred, STRIKE:Color.red, DEFLECT:Color.yellow, OFF_BALANCE:Color.darkgray, BLOCK:Color.cyan, INTERRUPT:Color.green, DISTRACT: Color.purple, TAUNT: Color.pink}

var data
var segments = [] setget set_segments
var segmentLines = []
var totalLength = 0
var targetLineFocus setget set_target_line_focus
var targetLine
var startPoint
var endPoint
var attackSpeed
var sourceCombatant
var targetCombatant
var sourceSegmentLength
var comingFromSourceCombatant
var isBlock = false
var isAttack = true

var curPosition = 0
var initialTime = 0
var initialProgress = 0
var balancePenalty = 0
var cost = {}

var currentlyPlacing = true
var combatScene
onready var sparksEmitter:Particles2D = find_node('Sparks', true, false)
onready var sparksEmitter2:Particles2D = find_node('Sparks2', true, false)
var powerLevel

func get_power_level():
	if !sourceCombatant: return {}
	var chargeStr = 0
	var strikeStr = 0
	var deflectStr = 0
	var blockStr = 0
	var interruptStr = 0
	var chargeScaleStr = 0
	var strikeScaleStr = 0
	var deflectScaleStr = 0
	var blockScaleStr = 0
	var interruptScaleStr = 0
	for segment in segments:
		var statMultiplier = 0
		var statScaling = 0
		var stats = segment.get('s', {})
		for stat in stats:
			statMultiplier += stats[stat]
			statScaling += sourceCombatant.get_stat(stat) * stats[stat]
		var density = segment.get('d', 1.0)
		var length = segment.get('l', 0.0)
		var strength = length * density * (statMultiplier * 100) # assumes all stats are 100 and full length
		var scaleStrength = density * statScaling # multiply by consumed length to get effect
		var type = segment.get('t')
		if type == CHARGE: 
				chargeStr += strength
				chargeScaleStr += scaleStrength
		if type == STRIKE: 
				strikeStr += strength
				strikeScaleStr += scaleStrength
		if type == DEFLECT: 
				deflectStr += strength
				deflectScaleStr += scaleStrength
		if type == BLOCK: 
				blockStr += strength
				blockScaleStr += scaleStrength
		if type == INTERRUPT: 
				interruptStr += strength
				interruptScaleStr += scaleStrength
	powerLevel = {
		"charge":chargeStr, 
		"strike":strikeStr, 
		"deflect":deflectStr, 
		"block":blockStr, 
		"interrupt":interruptStr, 
		"total":chargeStr+strikeStr+deflectStr+interruptStr,
		"charge_scale":chargeScaleStr,
		"strike_scale":strikeScaleStr, 
		"deflect_scale":deflectScaleStr, 
		"block_scale":blockScaleStr, 
		"interrupt_scale":interruptScaleStr, 
		}
	return powerLevel

func trigger_effect(segment, incrementalConsumedAmt):
	var type = segment.get('t', 0)
	if type == CHARGE: 
		sourceCombatant.trigger_charge(powerLevel.get('charge_scale', 0)*incrementalConsumedAmt, segment, self)
	elif type == BLOCK: 
		sourceCombatant.trigger_block(powerLevel.get('block_scale', 0)*incrementalConsumedAmt, segment, self)
		
func trigger_final_effect(segment):
	print('Segment final effect: '+to_json(segment))
	var type = segment.get('t', 0)
	if type == STRIKE: 
			sourceCombatant.trigger_strike(powerLevel.get('strike_scale', 0) * segment.get('l'), segment, self)
	if type == DEFLECT: 
			sourceCombatant.trigger_deflect(powerLevel.get('deflect_scale', 0) * segment.get('l'), segment, self)
	if type == INTERRUPT: 
			sourceCombatant.trigger_interrupt(powerLevel.get('interrupt_scale', 0) * segment.get('l'), segment, self)

# placementOffset is from the POV of the usingCombatant's half of the line (so 1.0 = the midpoint between the two combatants)
func setup(placementOffset=0, usingCombatant=combatScene.selectedCombatant):
	endPoint = targetLine.points[1]
	if usingCombatant == targetLine.sourceCombatant:
		attackSpeed = targetLine.sourceSegmentSpeed
		startPoint = targetLine.points[0]
		sourceCombatant = targetLine.sourceCombatant
		targetCombatant = targetLine.targetCombatant
		sourceSegmentLength = targetLine.sourceSegmentLength
		comingFromSourceCombatant = true
		curPosition = placementOffset #1.0/sourceSegmentLength * placementOffset
		balancePenalty = curPosition*1.2
	else:
		attackSpeed = targetLine.targetSegmentSpeed
		startPoint = targetLine.points[2]
		sourceCombatant = targetLine.targetCombatant
		targetCombatant = targetLine.sourceCombatant
		sourceSegmentLength = targetLine.targetSegmentLength
		comingFromSourceCombatant = false
		curPosition = placementOffset #1.0/sourceSegmentLength * placementOffset
		balancePenalty = curPosition*1.2
	curPosition = clamp(curPosition, 0, 1)
	segments[segments.size()-1]['l'] = balancePenalty
	initialTime = Calendar.combatTime

func deserialize(data):
	self.data = data
	set_segments(data.get('segments', []))
	isBlock = data.get('block', false)
	isAttack = data.get('attack', true)
	cost = data.get('cost', {})

func finish_placing():
	currentlyPlacing = false
	initialProgress = curPosition
	initialTime = Calendar.combatTime
	refreshTotalLength()
	powerLevel = get_power_level()
	update_endpoints(startPoint, endPoint)
	targetLine.add_technique(self)

func set_target_line_focus(focus):
	if focus:
		targetLine = focus.targetLine
	else:
		targetLine = null
	if targetLine:
		update_endpoints(targetLine.points[0], targetLine.points[targetLine.points.size()-1])
		initialTime = Calendar.combatTime
	else:
		startPoint = Vector2.ZERO
		endPoint = Vector2(-200, 0)

func update_endpoints(s:Vector2, e:Vector2):
	startPoint = s
	endPoint = e
	var angle = s.angle_to_point(e)
	var offsetAngle = deg2rad(80)
	if sparksEmitter:
		sparksEmitter.position = e + Vector2(3, -1).rotated(angle-deg2rad(90))
		sparksEmitter.rotation = angle - offsetAngle
	if sparksEmitter2:
		sparksEmitter2.position = e + Vector2(3, -1).rotated(angle+deg2rad(90))
		sparksEmitter2.rotation = angle + offsetAngle

func set_segments(val):
	for segment in val:
		add_segment(segment.get('t', 1), segment.get('l', 0), segment.get('d', 1.0), segment.get('s', {}))
	add_segment(OFF_BALANCE, 0)
	refreshTotalLength()
	powerLevel = get_power_level()

func add_segment(type, lengthInLinePercent, density=1, stats={}):
	segments.append({'t':type, 'l': lengthInLinePercent, 'd':density, 's':stats})
	totalLength += lengthInLinePercent

func refreshTotalLength():
	totalLength = 0
	for segment in segments:
		totalLength += segment.get('l',0)


func _ready():
#	set_target_line_focus(null)
	for segment in segments:
		var line = Line2D.new()
		line.width = 7
		line.points = [Vector2.ZERO, Vector2.ZERO]
		line.default_color = LINE_COLORS[segment.get('t', 0)]
		self.add_child(line)
		segmentLines.append(line)
	powerLevel = get_power_level()

func _process(delta):
	if targetLine:
		curPosition = initialProgress + (Calendar.combatTime - initialTime)*attackSpeed
	else:
		curPosition = 0
	render()

func render():
	if currentlyPlacing:
		# Check that the mouse cursor is close enough to some line that we want to render on top of it
		if combatScene.closestTargetLinePoint != null and combatScene.closestTargetLinePoint.visible:
			targetLine = combatScene.closestTargetLinePoint.parentLine
		else:
			targetLine = null
		# Check that the point we're close to is placed after the end of the latest technique on the timeline - you can't start preparing a punch and then toss a kick in front of it (at least not yet)
		if (targetLine != null):
			var latestProgressWeCanPlaceAt = targetLine.get_latest_add_offset(combatScene.selectedCombatant)
			var targetProgress = targetLine.get_offset_according_to_combatant(combatScene.closestTargetLinePoint.progress, combatScene.selectedCombatant)
			if targetProgress > latestProgressWeCanPlaceAt:
				targetLine = null
		# Check to see if we're hovering over a line that's appropriate for the kind of technique we're doing
		if (targetLine != null) and ((combatScene.selectedCombatant == targetLine.sourceCombatant and isAttack) or (combatScene.selectedCombatant == targetLine.targetCombatant and isBlock)):
			var targetProgress = targetLine.get_offset_according_to_combatant(combatScene.closestTargetLinePoint.progress, combatScene.selectedCombatant)
			setup(targetProgress, combatScene.selectedCombatant)
		else:
			targetLine = null
			curPosition = 0
			startPoint = get_global_mouse_position() + Vector2(10, 0)
			endPoint = startPoint - Vector2(100, 0)
			segments[segments.size()-1]['l'] = 0
	
	var t = curPosition
	var remainingSegments = false
	var shouldFireSparks = false
	for i in segmentLines.size():
		var segment = segments[i]
		var line = segmentLines[i]
		var startT = t
		t -= segment.get('l')
		var endT = t
		if targetLine and !currentlyPlacing:
			startT = min(startT, 1)
			endT = min(endT, 1)
		line.points[0] = lerp(startPoint, endPoint, startT)
		line.points[1] = lerp(startPoint, endPoint, endT)
		if endT >= 1:
			if !segment.get('done', false):
				segment['done'] = true
				segment['consumed'] = segment['l']
				trigger_final_effect(segment)
		else:
			if startT >= 1 and !segment.get('done', false):
				var consumedAmt = (segment.get('l')-(1.0-t))
				var incrementalConsumedAmt = consumedAmt - segment.get('consumed', 0)
				if incrementalConsumedAmt != 0:
					trigger_effect(segment, incrementalConsumedAmt)
					segment['consumed'] = consumedAmt
					shouldFireSparks = LINE_COLORS[segment.get('t', 0)]
			remainingSegments = true
	
	# Set off sparks if needed
	if shouldFireSparks and !sparksEmitter.emitting:
		sparksEmitter.emitting = true
		sparksEmitter.modulate = shouldFireSparks
		sparksEmitter2.emitting = true
		sparksEmitter2.modulate = shouldFireSparks
	elif !shouldFireSparks and sparksEmitter.emitting:
		sparksEmitter.emitting = false
		sparksEmitter2.emitting = false
	elif shouldFireSparks is Color and sparksEmitter.process_material.color != shouldFireSparks:
		sparksEmitter.modulate = shouldFireSparks
		sparksEmitter2.modulate = shouldFireSparks
		
	if !remainingSegments:
		print('Finished attack')
		targetLine.finish_attack(self)
		queue_free()

