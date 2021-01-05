extends Node2D
class_name AttackTechnique

# dodge: mitigates damage at the time of the hit
# block: reduces the effectivness
# deflect: interrupts windups, 

const EMPTY = 0 # no interrupt possible, other techniques can fit inside
const PREPARE = 1 # interruption will cancel following segments up until the next 'empty' 
const CHARGE = 2 # interruption will reduce the strength of the following hit segment
const STRIKE = 3 # interruption with a dodge, block or deflect will reduce damage, interruption with an attack does nothing
const PARRY = 4 # interrupts another attack that is striking or charging when it hits

const LINE_COLORS = [Color.transparent, Color.white, Color.darkred, Color.red, Color.blue]
var segments = [] setget set_segments
var segmentLines = []
var totalLength = 0
var targetLineFocus setget set_target_line_focus
var targetLine
var startPoint
var endPoint

var curPosition = 0
var initialTime = 0
var initialProgress = 0

var currentlyPlacing = true
var combatScene

func set_target_line_focus(focus):
	if focus:
		targetLine = focus.targetLine
	else:
		targetLine = null
	if targetLine:
		startPoint = targetLine.points[0]
		endPoint = targetLine.points[targetLine.points.size()-1]
		initialTime = Calendar.combatTime
	else:
		startPoint = Vector2.ZERO
		endPoint = Vector2(-200, 0)

func set_segments(val):
	for segment in val:
		add_segment(segment.get('t', 1), segment.get('l', 0))

func add_segment(type, lengthInLinePercent):
	segments.append({'t':type, 'l': lengthInLinePercent})
	totalLength += lengthInLinePercent

func _ready():
	combatScene = get_parent().get_parent()
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
		curPosition = initialProgress + (Calendar.combatTime - initialTime)/targetLine.pulseSpeed
	else:
		curPosition = 0
	render()

func render():
	if currentlyPlacing:
		if combatScene.closestTargetLinePoint != null and combatScene.closestTargetLinePoint.visible:
			targetLine = combatScene.closestTargetLinePoint.get_parent()
			curPosition = combatScene.closestTargetLinePoint.progress
			startPoint = targetLine.points[0]
			endPoint = targetLine.points[targetLine.points.size()-1]
		else:
			targetLine = null
			curPosition = 0
			startPoint = get_global_mouse_position() + Vector2(10, 0)
			endPoint = startPoint - Vector2(100, 0)
	
	var t = curPosition
	for i in segmentLines.size():
		var segment = segments[i]
		var line = segmentLines[i]
		var startT = t
		t -= segment.get('l')
		var endT = t
		if targetLine:
			startT = clamp(startT, 0, 1)
			endT = clamp(endT, 0, 1)
		line.points[0] = lerp(startPoint, endPoint, startT)
		line.points[1] = lerp(startPoint, endPoint, endT)
		if !segment.get('done', false) and endT >= 1:
			segment['done'] = true
			activate_segment(segment)

func activate_segment(segment):
	print('Activating segment: '+to_json(segment))

