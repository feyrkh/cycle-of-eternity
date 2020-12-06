extends Area2D

func _ready():
	self.gravity_vec = self.gravity_vec.rotated(self.rotation)
