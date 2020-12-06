extends Area2D

func _ready():
	self.gravity_vec = self.gravity_vec.rotated(self.rotation)
	deactivate()

func deactivate():
	print('deactivating ', self.name)
	hide()
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	set_process_input(false)
	space_override = SPACE_OVERRIDE_DISABLED

func activate():
	print('activating ', self.name)
	show()
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	set_process_input(true)
	space_override = SPACE_OVERRIDE_COMBINE
