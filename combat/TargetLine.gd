extends Line2D

const offsetSmall = deg2rad(12)
const offset180 = deg2rad(180)
const caratCount = 4
const MIN_SEGMENT_LENGTH = 0.2
const DEFAULT_SEGMENT_SPEED = 0.1 # full-lines per second

var sourceCombatant:Combatant
var targetCombatant:Combatant
var targetLineFocus
var closestPoint
var mirrorPoint


var offsetFromNodeCenter = 48
var offsetFromCenterlineVector = 3
var angleBetweenNodes = 0

var sourceTechniques = [] # attacks or blocks travelling along this line
var targetTechniques = [] # attacks or blocks travelling along this line
var sourceCarats = []
var targetCarats = []
var sourceBetweenCaratOffset = 1.0/caratCount
var targetBetweenCaratOffset = 1.0/caratCount
var offsetRadians = 0
var pauseOffset = 0

var defaultColor

var sourceSegmentLength = 0.5
var targetSegmentLength = 0.5
var sourceSegmentSpeed = DEFAULT_SEGMENT_SPEED
var targetSegmentSpeed = DEFAULT_SEGMENT_SPEED

func add_technique(attackTech):
	if sourceCombatant == attackTech.sourceCombatant:
		self.sourceTechniques.append(attackTech)
	else:
		self.targetTechniques.append(attackTech)

func update_combat_speed(newSpeed):
	$AnimationPlayer.playback_speed = newSpeed
#	if newSpeed == 0:
#		default_color = Color(1, 1, 1, 0.3)
#	else:
#		default_color = defaultColor

func _ready():
	if !closestPoint:
		closestPoint = find_node('ClosestPoint')
		remove_child(closestPoint)
		get_parent().get_parent().find_node('LineMarkerLayer').add_child(closestPoint)
	if !mirrorPoint:
		mirrorPoint = find_node('MirrorPoint')
		remove_child(mirrorPoint)
		get_parent().get_parent().find_node('LineMarkerLayer').add_child(mirrorPoint)
	$AnimationPlayer.play('pulse')
	$AnimationPlayer.seek(fmod(OS.get_system_time_msecs()/1000.0, $AnimationPlayer.current_animation_length))
	for i in caratCount:
		var c = Sprite.new()
		c.texture = load('res://img/carat_icon.png')
		c.scale = Vector2(0.25, 0.25)
		c.modulate = Color.white #sourceCombatant.color
		c.modulate.a = 0.9
		sourceCarats.append(c)
		add_child(c)
		c = Sprite.new()
		c.texture = load('res://img/carat_icon.png')
		c.scale = Vector2(0.25, 0.25)
		c.modulate = Color.white #targetCombatant.color
		c.modulate.a = 0.9
		targetCarats.append(c)
		add_child(c)
	Event.connect("update_target_lines", self, "update_attack_line", [], CONNECT_DEFERRED)
	Event.emit_signal("update_target_lines")
	default_color.a = 0.3
	defaultColor = default_color
	Event.connect("combat_speed_multiplier", self, "update_combat_speed")
	$Midpoint/Pulser.pulseColor = sourceCombatant.color
	$Midpoint/Pulser.startColor = targetCombatant.color
	update_combat_speed(Calendar.combatSpeed)

func cleanup():
	if get_parent():
		get_parent().remove_child(self)

func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.play('pulse')

func _process(delta):
	var pulseCaratOffset
	#carats coming from source node
	#if Calendar.combatSpeed == 0:
	#	pauseOffset += delta
	pulseCaratOffset = fmod(((Calendar.combatTime+pauseOffset)*sourceSegmentSpeed/2), 1.0)#/sourceSegmentLength
	for carat in sourceCarats:
		if pulseCaratOffset < 0 or pulseCaratOffset > sourceSegmentLength: 
			carat.visible = false
		else: 
			carat.visible = true
		carat.position = lerp(points[0], points[2], pulseCaratOffset)
		#pulseCaratOffset = fmod(pulseCaratOffset+sourceBetweenCaratOffset/sourceSegmentLength, 1.0)
		pulseCaratOffset = pulseCaratOffset + sourceBetweenCaratOffset
		if pulseCaratOffset > sourceSegmentLength:
			pulseCaratOffset -= 1.0
	# carats coming from target node
	pulseCaratOffset = fmod(((Calendar.combatTime+pauseOffset)*targetSegmentSpeed/2), 1.0)#/targetSegmentLength
	for carat in targetCarats:
		if pulseCaratOffset > targetSegmentLength:
			pulseCaratOffset -= 1.0
		if pulseCaratOffset < 0 or pulseCaratOffset > targetSegmentLength:
			carat.visible = false
		else:
			carat.visible = true
		carat.position = lerp(points[2], points[0], pulseCaratOffset)
		pulseCaratOffset = pulseCaratOffset + targetBetweenCaratOffset
		#pulseCaratOffset = fmod(pulseCaratOffset+targetBetweenCaratOffset/targetSegmentLength, 1.0)
	# find the point on the line the mouse cursor is closest to
	var mouseProgress = Util.get_segment_progress_from_point(get_global_mouse_position(), points[0], points[points.size()-1])
	var progressPoint = lerp(points[0], points[points.size()-1], mouseProgress)
	closestPoint.position = progressPoint
	closestPoint.progress = mouseProgress
	var mirrorProgress = sourceSegmentLength+(sourceSegmentLength-mouseProgress)
	if mirrorProgress < 0 or mirrorProgress > 1:
		closestPoint.mirrorVisible = false
	else:
		var mirrorPointPosition = lerp(points[0], points[2], mirrorProgress)
		mirrorPoint.position = mirrorPointPosition
		closestPoint.mirrorVisible = true
	

# look at the end of the last technique on the line coming from the given combatant.
func get_latest_add_offset(forCombatant):
	var lastTechnique
	if forCombatant == sourceCombatant:
		if sourceTechniques.size() == 0: 
			return 1
		lastTechnique = sourceTechniques[sourceTechniques.size()-1]
	else:
		if targetTechniques.size() == 0: return 1
		lastTechnique = targetTechniques[targetTechniques.size()-1]
	return lastTechnique.curPosition - lastTechnique.totalLength

# Ex, assuming a line that's divided with 0.6 of its length for source and 0.4 for its target:
# get_offset_according_to_combatant(0, source) = 0/0.6 = 0
# get_offset_according_to_combatant(0, target) = (1-0)/0.4 = 2.333 (it would take 2.333 full 0.4 segments to get from the target to where the source starts)
# get_offset_according_to_combatant(1, source) = 1/0.6 = 1.666
# get_offset_according_to_combatant(1, target) = (1-1)/0.4 = 0
# get_offset_according_to_combatant(0.5, source) = 0.5/0.6 = 0.833
# get_offset_according_to_combatant(0.5, target) = (1-0.5)/0.4 = 1.250
# get_offset_according_to_combatant(0.6, source) = 0.6/0.6 = 1.0
# get_offset_according_to_combatant(0.6, target) = (1-0.6)/0.4 = 1.0
# get_offset_according_to_combatant(0.7, source) = 0.7/0.6 = 1.166
# get_offset_according_to_combatant(0.7, target) = (1-0.7)/0.4 = 0.75
func get_offset_according_to_combatant(offsetAmt, combatant):
	if combatant == sourceCombatant:
		return offsetAmt / sourceSegmentLength
	else:
		return (1-offsetAmt) / targetSegmentLength

func finish_attack(attackTech):
	if attackTech.sourceCombatant == sourceCombatant:
		sourceTechniques.erase(attackTech)
	else:
		targetTechniques.erase(attackTech)

func update_attack_line():
	if !targetCombatant or !sourceCombatant: return
	if !get_tree(): return
	var fromSourceToTarget = false
	var fromTargetToSource = false
	var offsetCount = 0
	# See if we have a line in both directions or not - if not then we can start from a straight line between the node centers. Otherwise we have to offset by 1 so we don't overlap.
	# If we don't do this then it looks a little weird when you just have one target line between the nodes, since it's offset.
	for line in get_tree().get_nodes_in_group("targetLine"):
		if line.sourceCombatant == self.sourceCombatant and line.targetCombatant == self.targetCombatant:
			fromSourceToTarget = true
		elif line.sourceCombatant == self.targetCombatant and line.targetCombatant == self.sourceCombatant:
			fromTargetToSource = true
		if fromSourceToTarget and fromTargetToSource: 
			break
		
	if fromSourceToTarget and fromTargetToSource: # if we have both incoming and outgoing, bump us over by 1
		offsetCount = 1
	
	var attackSpeed = float(sourceCombatant.get_attack_speed())
	var defenseSpeed = float(targetCombatant.get_defense_speed())
	sourceSegmentLength = 1.0 - (attackSpeed / (attackSpeed+defenseSpeed))
	targetSegmentLength = 1.0 - sourceSegmentLength
	
	sourceBetweenCaratOffset = 1.0/caratCount
	targetBetweenCaratOffset = 1.0/caratCount
	sourceSegmentSpeed = (DEFAULT_SEGMENT_SPEED / sourceSegmentLength) / 2
	targetSegmentSpeed = (DEFAULT_SEGMENT_SPEED / targetSegmentLength) / 2
	if sourceSegmentLength < MIN_SEGMENT_LENGTH:
		# If the segment is too short, that means the source was much faster than the target. We don't want super-tiny segments, so we need to enlarge the segment
		# but since we're making the segment longer, it also needs to move faster...at least for non-blocking maneuvers.
		# Ex: defender has speed of 100, attacker has speed of 900; this gives segment sizes of 0.1 for the attacker and 0.9 for defender
		# default speed is 0.1 per second (10 seconds to traverse a full line)
		var multiplierNeeded = MIN_SEGMENT_LENGTH/sourceSegmentLength # ex: length of 0.1 must become 2x longer to reach minimum length, so multiplierNeeded=2
		sourceSegmentLength = MIN_SEGMENT_LENGTH 
		sourceSegmentSpeed = DEFAULT_SEGMENT_SPEED*multiplierNeeded # ex: Since we doubled the length we must double the speed - it previously took 1 second to traverse the 0.1 length line, so we double the speed so it still takes 1 second
		# Since we increased the length of the source segment we have to decrease the target segment length and its speed
		var divisorNeeded = (1-sourceSegmentLength)/targetSegmentLength # ex: length of 0.9 must become 0.8, so that's 0.8/0.9 or ~0.89 original length. Because we multiplied length by 0.89, we also have to multiply speed by that much
		targetSegmentLength = 1-MIN_SEGMENT_LENGTH
		targetSegmentSpeed = DEFAULT_SEGMENT_SPEED*divisorNeeded
	elif targetSegmentLength < MIN_SEGMENT_LENGTH:
		var multiplierNeeded = MIN_SEGMENT_LENGTH/targetSegmentLength 
		targetSegmentLength = MIN_SEGMENT_LENGTH 
		targetSegmentSpeed = DEFAULT_SEGMENT_SPEED*multiplierNeeded 
		var divisorNeeded = (1-targetSegmentLength)/sourceSegmentLength
		sourceSegmentLength = 1-MIN_SEGMENT_LENGTH
		sourceSegmentSpeed = DEFAULT_SEGMENT_SPEED*divisorNeeded
		
	var curOffsetRadians = offsetRadians + (offsetCount * offsetSmall)
	
	# get the angle from the source node to the target node relative to the X axis
	angleBetweenNodes = targetCombatant.rect_position.angle_to_point(sourceCombatant.rect_position)
	# get the point on the edge of the source node where the line would originate from if we wanted to go in a straight line from node to node, offset a little
	var sourceRadiusPoint = Vector2(offsetFromNodeCenter, 0)
	sourceRadiusPoint = sourceRadiusPoint.rotated(angleBetweenNodes+curOffsetRadians)
	sourceRadiusPoint += sourceCombatant.rect_position
	for carat in sourceCarats:
		carat.rotation_degrees = rad2deg(angleBetweenNodes)
	for carat in targetCarats:
		carat.rotation_degrees = rad2deg(angleBetweenNodes+PI)
	# get the point on the edge 
	var targetRadiusPoint = Vector2(offsetFromNodeCenter, 0)
	targetRadiusPoint = targetRadiusPoint.rotated(angleBetweenNodes+offset180-curOffsetRadians)
	targetRadiusPoint += targetCombatant.rect_position
	points[0] = sourceRadiusPoint
	points[1] = lerp(sourceRadiusPoint, targetRadiusPoint, sourceSegmentLength)
	points[2] = targetRadiusPoint
	$Midpoint.position = points[1]
	$AnimationPlayer.seek(fmod(OS.get_system_time_msecs()/1000.0, $AnimationPlayer.current_animation_length))
	
	for tech in sourceTechniques:
		tech.update_endpoints(points[0], points[1])
	for tech in targetTechniques:
		tech.update_endpoints(points[2], points[1])
	
