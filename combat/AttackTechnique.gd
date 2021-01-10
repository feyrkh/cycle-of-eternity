extends Node2D
class_name AttackTechnique

# dodge: mitigates damage at the time of the hit
# block: reduces the effectivness
# deflect: interrupts windups, 

const EMPTY = 0 # no interrupt possible, other techniques can fit inside
const PREPARE = 1 # interruption by an attack
const CHARGE = 2 # store charge to be released by a strike
const STRIKE = 3 # do damage, multiply by stored charge
const DEFLECT = 4 # interrupts another attack that is striking when it hits
const OFF_BALANCE = 5
const BLOCK = 6 # directly opposes strikes, does not affect charge
const INTERRUPT = 7 # interrupts charging

const LINE_COLORS = [Color.transparent, Color.white, Color.darkred, Color.red, Color.yellow, Color.darkgray, Color.cyan, Color.green]

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

var currentlyPlacing = true
var combatScene
onready var sparksEmitter:Particles2D = find_node('Sparks', true, false)
onready var sparksEmitter2:Particles2D = find_node('Sparks2', true, false)

func deserialize(data):
	self.data = data
	set_segments(data.get('segments', []))
	isBlock = data.get('block', false)
	isAttack = data.get('attack', true)

func finish_placing():
	currentlyPlacing = false
	initialProgress = curPosition
	initialTime = Calendar.combatTime
	refreshTotalLength()
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
	sparksEmitter.position = e + Vector2(3, -1).rotated(angle-deg2rad(90))
	sparksEmitter.rotation = angle - offsetAngle
	sparksEmitter2.position = e + Vector2(3, -1).rotated(angle+deg2rad(90))
	sparksEmitter2.rotation = angle + offsetAngle

func set_segments(val):
	for segment in val:
		add_segment(segment.get('t', 1), segment.get('l', 0), segment.get('d', 1.0), segment.get('s', {}))
	add_segment(OFF_BALANCE, 0)

func add_segment(type, lengthInLinePercent, density=1, stats={}):
	segments.append({'t':type, 'l': lengthInLinePercent})
	totalLength += lengthInLinePercent

func refreshTotalLength():
	totalLength = 0
	for segment in segments:
		totalLength += segment.get('l',0)

func _ready():
	set_target_line_focus(null)
	for segment in segments:
		var line = Line2D.new()
		line.width = 7
		line.points = [Vector2.ZERO, Vector2.ZERO]
		line.default_color = LINE_COLORS[segment.get('t', 0)]
		self.add_child(line)
		segmentLines.append(line)

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
			targetLine = combatScene.closestTargetLinePoint.get_parent()
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
			endPoint = targetLine.points[1]
			if combatScene.selectedCombatant == targetLine.sourceCombatant:
				attackSpeed = targetLine.sourceSegmentSpeed
				startPoint = targetLine.points[0]
				sourceCombatant = targetLine.sourceCombatant
				targetCombatant = targetLine.targetCombatant
				sourceSegmentLength = targetLine.sourceSegmentLength
				comingFromSourceCombatant = false
			else:
				attackSpeed = targetLine.targetSegmentSpeed
				startPoint = targetLine.points[2]
				sourceCombatant = targetLine.targetCombatant
				targetCombatant = targetLine.sourceCombatant
				sourceSegmentLength = targetLine.targetSegmentLength
				comingFromSourceCombatant = true
			curPosition = combatScene.closestTargetLinePoint.progress
			if comingFromSourceCombatant: 
				curPosition = 1-curPosition
			curPosition = 1.0/sourceSegmentLength * curPosition
			curPosition = clamp(curPosition, 0, 1)
			balancePenalty = curPosition*1.2
			segments[segments.size()-1]['l'] = balancePenalty
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
				activate_segment(segment)
		else:
			if startT >= 1 and !segment.get('done', false):
				var consumedAmt = segment.get('consumed', 0) + (startT - 1.0)
				segment['consumed'] = consumedAmt + segment.get('consumed', 0)
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

func activate_segment(segment):
	print('Activating segment: '+to_json(segment))

