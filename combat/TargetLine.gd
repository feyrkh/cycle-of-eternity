extends Line2D

const offsetSmall = deg2rad(12)
const offset180 = deg2rad(180)
const caratCount = 4
const defaultPulseSpeed = 5

var sourceNode
var targetNode
var targetLineFocus

var offsetFromNodeCenter = 46
var offsetFromCenterlineVector = 3
var angleBetweenNodes = 0

var pulseSpeed = 5 # seconds it takes for a pulse to travel from one end to the other

var pulseCarats = []
var betweenCaratOffset = 1.0/caratCount
var offsetRadians = 0
var pauseOffset = 0

var defaultColor

func update_combat_speed(newSpeed):
	$AnimationPlayer.playback_speed = newSpeed
	if newSpeed == 0:
		default_color = Color(1, 1, 1, 0.3)
	else:
		default_color = defaultColor

func _ready():
	$AnimationPlayer.play('pulse')
	$AnimationPlayer.seek(fmod(OS.get_system_time_msecs()/1000.0, $AnimationPlayer.current_animation_length))
	for i in caratCount:
		var c = Sprite.new()
		c.texture = load('res://img/carat_icon.png')
		c.scale = Vector2(0.25, 0.25)
		c.modulate = default_color
		c.modulate.a = 0.9
		pulseCarats.append(c)
		add_child(c)
	Event.connect("update_target_lines", self, "update_attack_line", [], CONNECT_DEFERRED)
	Event.emit_signal("update_target_lines")
	default_color.a = 0.3
	defaultColor = default_color
	Event.connect("combat_speed_multiplier", self, "update_combat_speed")
	update_combat_speed(Calendar.combatSpeed)

func cleanup():
	if get_parent():
		get_parent().remove_child(self)

func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.play('pulse')

func _process(delta):
	var pulseCaratOffset
	if Calendar.combatSpeed == 0:
		pauseOffset += delta
		pulseCaratOffset = fmod(Calendar.combatTime+pauseOffset, pulseSpeed)/pulseSpeed
	else:
		pulseCaratOffset = fmod(Calendar.combatTime+pauseOffset, pulseSpeed)/pulseSpeed
	for carat in pulseCarats:
		carat.position = lerp(points[0], points[points.size()-1], pulseCaratOffset)
		pulseCaratOffset = fmod(pulseCaratOffset+betweenCaratOffset, 1.0)
	var mouseProgress = Util.get_segment_progress_from_point(get_global_mouse_position(), points[0], points[points.size()-1])
	var progressPoint = lerp(points[0], points[points.size()-1], mouseProgress)
	$ClosestPoint.position = progressPoint
	$ClosestPoint.progress = mouseProgress

func update_attack_line():
	if !targetNode or !sourceNode: return
	if !get_tree(): return
	var fromSourceToTarget = false
	var fromTargetToSource = false
	var offsetCount = 0
	# See if we have a line in both directions or not - if not then we can start from a straight line between the node centers. Otherwise we have to offset by 1 so we don't overlap.
	# If we don't do this then it looks a little weird when you just have one target line between the nodes, since it's offset.
	for line in get_tree().get_nodes_in_group("targetLine"):
		if line.sourceNode == self.sourceNode and line.targetNode == self.targetNode:
			fromSourceToTarget = true
		elif line.sourceNode == self.targetNode and line.targetNode == self.sourceNode:
			fromTargetToSource = true
		if fromSourceToTarget and fromTargetToSource: 
			break
		
	if fromSourceToTarget and fromTargetToSource: # if we have both incoming and outgoing, bump us over by 1
		offsetCount = 1
	
	var curOffsetRadians = offsetRadians + (offsetCount * offsetSmall)
	
	# get the angle from the source node to the target node relative to the X axis
	angleBetweenNodes = targetNode.rect_position.angle_to_point(sourceNode.rect_position)
	# get the point on the edge of the source node where the line would originate from if we wanted to go in a straight line from node to node, offset a little
	var sourceRadiusPoint = Vector2(offsetFromNodeCenter, 0)
	sourceRadiusPoint = sourceRadiusPoint.rotated(angleBetweenNodes+curOffsetRadians)
	sourceRadiusPoint += sourceNode.rect_position
	for carat in pulseCarats:
		carat.rotation_degrees = rad2deg(angleBetweenNodes)
	# get the point on the edge 
	var targetRadiusPoint = Vector2(offsetFromNodeCenter, 0)
	targetRadiusPoint = targetRadiusPoint.rotated(angleBetweenNodes+offset180-curOffsetRadians)
	targetRadiusPoint += targetNode.rect_position
	points[0] = sourceRadiusPoint
	points[1] = targetRadiusPoint
	$AnimationPlayer.seek(fmod(OS.get_system_time_msecs()/1000.0, $AnimationPlayer.current_animation_length))
	
