extends OrganizerEntry


var ki:Ki

onready var elementLabel = $VBoxContainer/HBoxContainer2/VBoxContainer2/ElementLabel
onready var qualityLabel = $VBoxContainer/HBoxContainer2/VBoxContainer2/QualityLabel
onready var energyLabel = $VBoxContainer/HBoxContainer2/VBoxContainer2/EnergyLabel
onready var velocityLabel = $VBoxContainer/HBoxContainer2/VBoxContainer2/VelocityLabel

func _ready():
	update_contents()
	
func configure(ki:Ki):
	self.ki = ki
	
func update_contents():
	if !ki: return
	elementLabel.text = KiUtil.ElementName[ki.ki_element]
	qualityLabel.text = KiUtil.RefinementName[ki.ki_quality]
	energyLabel.text = str(ki.ki_energy)
	var velocityPct = int(100*ki.linear_velocity.length() / ki.max_velocity)
	velocityLabel.text = str(velocityPct)+'%'

func _on_Timer_timeout():
	update_contents()
