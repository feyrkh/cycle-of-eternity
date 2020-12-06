extends RigidBody2D

export var min_velocity = 5
export var max_velocity = 100
export var min_angular_velocity = 0.5
export var max_angular_velocity = 0.5
var max_velocity_squared = max_velocity*max_velocity
const defaultScaleX = 0.1
const defaultScaleY = 0.1
const defaultAlpha = 0.9

const HIGHLIGHT_LAYER = 18
var ki_element:int


export(Material) var highlightMaterial

func _ready():
	linear_velocity = Vector2(rand_range(-100, 100), rand_range(-100, 100)).normalized() * rand_range(min_velocity, max_velocity)
	linear_velocity = linear_velocity.rotated(rand_range(0, deg2rad(360)))
	angular_velocity = rand_range(min_angular_velocity, max_angular_velocity)
	
	ki_element = randi()%5
	self.collision_layer = 1 << ki_element | 1 << HIGHLIGHT_LAYER
	self.collision_mask = KiUtil.ElementCollisionMask[ki_element]
	$Image.texture = KiUtil.ElementImages[ki_element]
	$Image.modulate = Color.white
	$Image.modulate.a = defaultAlpha
	#$Image.modulate = KiUtil.ElementColor[ki_element]
	
	$'/root/Event'.connect('chakraZoom', self, 'on_chakra_zoom')

func _physics_process(delta):
	if self.linear_velocity.length_squared() > max_velocity_squared:
		self.linear_velocity *= 0.98

func on_chakra_zoom(zoomAmt):
	var alpha
	var scaleAmt = 0
	
	if zoomAmt.x <= 1: 
		alpha = 1.0
	else: 
		alpha = max(1-(zoomAmt.x/10), 0)
		scaleAmt = (1-alpha)*10
		$Image.scale = Vector2(defaultScaleX*scaleAmt, defaultScaleY*scaleAmt)
		$Image.modulate.a = max(0.15, alpha*defaultAlpha)

func highlight():
	if highlightMaterial:
		material = highlightMaterial

func unhighlight():
	material = null
