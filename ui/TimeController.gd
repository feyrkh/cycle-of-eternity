extends Control

const TIME_MODE_CALENDAR = 0
const TIME_MODE_PHYSICS = 1
const TIME_MODE_COMBAT = 2

var previousLevel = 0
var curLevel = 0
var days_per_second = 0

var levels = [0, 1, 3, 180]
var physics_steps = [30, 30, levels[2]*30, levels[3]*30]
var days_per_second_steps = [0, 1.0/2, 2, 5]
var combat_speed_steps = [0, 1.0, 2, 5]

var dayFraction = 0
var enabled = true
var _pause_key_mutex_count = 0

var mode = TIME_MODE_CALENDAR setget set_mode

signal day_passed()
signal day_fraction_update(newDayFraction)

func _ready():
	Event.connect("save_state_loaded", self, "on_save_state_loaded")
	Event.connect("time_should_pause", self, "on_time_should_pause")
	Event.connect("pause_key_mutex", self, "on_pause_key_mutex")
	Event.connect("entering_combat", self, "on_enter_combat")
	Event.connect("leaving_combat", self, "on_leave_combat")

func on_enter_combat(combatScene):
	mode = TIME_MODE_COMBAT

func on_leave_combat(combatScene):
	mode = TIME_MODE_CALENDAR

func _process(delta):
	if enabled:
		if _pause_key_mutex_count <= 0 and Input.is_action_just_released("ui_pause"):
			if curLevel == 0:
				set_speed(previousLevel)
			else:
				set_speed(0)
		match mode:
			TIME_MODE_CALENDAR: process_calendar(delta)
			_: pass
			
#	elif Input.is_action_just_released("ui_time_scroll"):
#		set_speed(curLevel+1)
#	elif Input.is_action_just_released("ui_time_scroll_reverse"):
#		set_speed(curLevel-1)

func process_calendar(delta):
	dayFraction += delta*days_per_second
	while dayFraction > 1:
		emit_signal('day_passed')
		dayFraction -= 1
	emit_signal('day_fraction_update', dayFraction)


func set_mode(val):
	if val != mode:
		set_speed(0)
	mode = val

func disable_on_conversation(state):
	set_enabled(state == 0)
	
func reenable():
	set_enabled(true)
	days_per_second = days_per_second_steps[curLevel]

func disable():
	set_enabled(false)
	days_per_second = 0
	
func set_enabled(enabled):
	self.enabled = enabled
	if !enabled: # text output is happening, disable
		print('disabling ', name)
		self.modulate = Color.darkgray
	else: 
		print('enabling ', name)
		self.modulate = Color.white

func set_speed(newLevel):
	if !GameState.settings.get('allowTimePass'):
		return
	for i in get_child_count():
		if newLevel != i: 
			get_child(i).pressed = false
		else:
			get_child(i).pressed = true
	newLevel = newLevel % levels.size()
	if newLevel < 0: newLevel += levels.size()
	previousLevel = curLevel
	curLevel = newLevel
	if previousLevel == 0 && curLevel == 0: previousLevel = 1
	if previousLevel != 0 && curLevel != 0: previousLevel = 0
	match mode:
		TIME_MODE_CALENDAR: days_per_second = days_per_second_steps[curLevel]
		TIME_MODE_COMBAT: Event.emit_signal("combat_speed_multiplier", combat_speed_steps[curLevel])
		TIME_MODE_PHYSICS: set_physics_speed(newLevel)

func set_physics_speed(newLevel):
	if !GameState.settings.get('allowTimePass'):
		return
	newLevel = newLevel % levels.size()
	if newLevel < 0: newLevel += levels.size()
	previousLevel = curLevel
	curLevel = newLevel
	if previousLevel == 0 && curLevel == 0: previousLevel = 1
	if previousLevel != 0 && curLevel != 0: previousLevel = 0
	Engine.time_scale = levels[curLevel]
	Engine.iterations_per_second = physics_steps[curLevel]
	print('setting time_scale to ', Engine.time_scale)
	
func on_save_state_loaded():
	set_speed(0)
	dayFraction = 0
	emit_signal('day_fraction_update', dayFraction)

func on_time_should_pause():
	if curLevel != 0:
		set_speed(0)

func on_pause_key_mutex(amt):
	_pause_key_mutex_count += amt
	if _pause_key_mutex_count < 0: _pause_key_mutex_count = 0
