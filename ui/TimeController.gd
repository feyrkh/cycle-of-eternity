extends PanelContainer

var previousLevel = 0
var curLevel = 1

var levels = [0, 1, 3, 8]
var physics_steps = [60, 60, 90, 600]

func _process(delta):
	pass
#	if Input.is_action_just_released("ui_pause"):
#		if curLevel == 0:
#			set_speed(previousLevel)
#		else:
#			set_speed(0)
#	elif Input.is_action_just_released("ui_time_scroll"):
#		set_speed(curLevel+1)
#	elif Input.is_action_just_released("ui_time_scroll_reverse"):
#		set_speed(curLevel-1)
		
func set_speed(newLevel):
	newLevel = newLevel % levels.size()
	if newLevel < 0: newLevel += levels.size()
	previousLevel = curLevel
	curLevel = newLevel
	if previousLevel == 0 && curLevel == 0: previousLevel = 1
	if previousLevel != 0 && curLevel != 0: previousLevel = 0
	Engine.time_scale = levels[curLevel]
	Engine.iterations_per_second = physics_steps[curLevel]
	print('setting time_scale to ', Engine.time_scale)
	grab_focus()
