extends AcceptDialog

var ki:Ki

onready var elementLabel = $PanelContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/ElementLabel
onready var qualityLabel = $PanelContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/QualityLabel
onready var energyLabel = $PanelContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/EnergyLabel
onready var velocityLabel = $PanelContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/VelocityLabel

func _ready():
	for child in get_children():
		if child is HBoxContainer: 
			child.queue_free()
			break
	_on_KiQueryPopup_resized()
	if !get_parent().get_parent(): popup()
	update_contents()


func _on_KiQueryPopup_resized():
	$PanelContainer.rect_min_size = self.rect_size - Vector2(1,1)

func configure(ki:Ki):
	self.ki = ki
	
func _on_Timer_timeout():
	update_contents()

func update_contents():
	if !ki: return
	elementLabel.text = KiUtil.ElementName[ki.ki_element]
	qualityLabel.text = KiUtil.RefinementName[ki.ki_quality]
	energyLabel.text = str(ki.ki_energy)
	var velocityPct = int(100*ki.linear_velocity.length() / ki.max_velocity)
	velocityLabel.text = str(velocityPct)+'%'
