extends Line2D


const offset180 = deg2rad(180)
const caratCount = 4

var sourceNode
var targetNode
var offsetFromNodeCenter = 46
var offsetFromCenterlineVector = 3
var angleBetweenNodes = 0

var pulseSpeed = 5 # seconds it takes for a pulse to travel from one end to the other

var pulseCarats = []
var betweenCaratOffset = 1.0/caratCount
var offsetRadians = deg2rad(10)


func _ready():
	$AnimationPlayer.play('pulse')
	for i in caratCount:
		var c = Sprite.new()
		c.texture = load('res://img/carat_icon.png')
		c.scale = Vector2(0.25, 0.25)
		c.modulate = default_color
		c.modulate.a = 0.9
		pulseCarats.append(c)
		add_child(c)
	update_attack_line()
	Event.connect("update_target_lines", self, "update_attack_line")
	default_color.a = 0.3

func cleanup():
	pass

func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.play('pulse')

func _process(delta):
	var pulseCaratOffset = fmod(Calendar.combatTime, pulseSpeed)/pulseSpeed
	for carat in pulseCarats:
		carat.position = lerp(points[0], points[points.size()-1], pulseCaratOffset)
		pulseCaratOffset = fmod(pulseCaratOffset+betweenCaratOffset, 1.0)
		

func update_attack_line():
	if !targetNode or !sourceNode: return
	# get the angle from the source node to the target node relative to the X axis
	angleBetweenNodes = targetNode.rect_position.angle_to_point(sourceNode.rect_position)
	# get the point on the edge of the source node where the line would originate from if we wanted to go in a straight line from node to node, offset a little
	var sourceRadiusPoint = Vector2(offsetFromNodeCenter, 0)
	sourceRadiusPoint = sourceRadiusPoint.rotated(angleBetweenNodes+offsetRadians)
	sourceRadiusPoint += sourceNode.rect_position
	for carat in pulseCarats:
		carat.rotation_degrees = rad2deg(angleBetweenNodes)
	# get the point on the edge 
	var targetRadiusPoint = Vector2(offsetFromNodeCenter, 0)
	targetRadiusPoint = targetRadiusPoint.rotated(angleBetweenNodes+offset180-offsetRadians)
	targetRadiusPoint += targetNode.rect_position
	points[0] = sourceRadiusPoint
	points[1] = targetRadiusPoint
	
