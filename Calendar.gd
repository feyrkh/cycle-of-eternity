extends Node

var combatTime = 0
var combatSpeed = 0

func _ready():
	Event.connect("after_pass_time", self, "on_after_pass_time")
	Event.connect("entering_combat", self, "on_entering_combat")
	Event.connect("leaving_combat", self, "on_leaving_combat")
	Event.connect("combat_speed_multiplier", self, "update_combat_speed")
	set_process(false)
	update_combat_speed(0)
	
func combat_lerp(from, to, lerpTimeSeconds):
	return lerp(from, to, fmod(combatTime, lerpTimeSeconds)/lerpTimeSeconds)
	
func os_lerp(from, to, lerpTimeSeconds):
	return lerp(from, to, fmod(OS.get_system_time_msecs()/1000.0, lerpTimeSeconds)/lerpTimeSeconds)

func update_combat_speed(newSpeed):
	combatSpeed = newSpeed
	
func on_entering_combat(combatScene):
	combatSpeed = 0
	set_process(true)

func on_leaving_combat(combatScene):
	combatSpeed = 0
	set_process(false)

func _process(delta):
	combatTime += delta * combatSpeed

func on_after_pass_time():
	if !GameState.settings.get('allowTimePass'):
		return
	var curDay = get_date() + 1
	GameState.settings['calendarDate'] = curDay
	Event.emit_signal("after_calendar_update", curDay)

func get_date():
	return int(GameState.settings.get('calendarDate', 0))

func get_formatted_date():
	var curDate = get_date()
	var curDayOfMonth = (curDate % 30)
	curDate -= curDayOfMonth
	var curMonth = floor((curDate % 360)/30)
	var curYear = floor(curDate/360)
	return "%02d/%02d/%d"%[curDayOfMonth+1, curMonth+1, curYear+820]

