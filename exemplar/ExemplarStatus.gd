extends Control

export(int) var barLength = 200
export(int) var barHeight = 20
export(int) var sidePadding = 14
var exemplarData

func _ready():
	for panel in [find_node('HealthPanel'), find_node('StaminaPanel'), find_node('FocusPanel')]:
		panel.rect_min_size = Vector2(barLength, barHeight)
	update_bar_sizes()

func update_bar_sizes():
	if exemplarData:
		_update_bar_size(find_node('StatusBarDisplay'), 'health')
		_update_bar_size(find_node('StaminaBar'), 'fatigue')
		_update_bar_size(find_node('FocusBar'), 'focus')

func _update_bar_size(bar, statName):
	var totalLength = bar.get_parent().rect_size.x - sidePadding
	var stat = max(0, exemplarData.get_stat(statName))
	var maxStat = exemplarData.get_stat('max_'+statName)
	if maxStat <= 0: 
		bar.rect_min_size = Vector2(totalLength, 0)
		return
	var pct = (stat/maxStat)
	var barLen = round(pct*totalLength)
	bar.rect_min_size = Vector2(barLen, 0)
