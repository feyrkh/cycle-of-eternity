extends Timer

export var visible = false
export(NodePath) var blinkTargetPath
onready var blinkTarget = get_node(blinkTargetPath)

func _ready():
	blinkTarget.visible = visible

func stopBlinking():
	visible = false
	blinkTarget.visible = visible
	stop()

func _on_BlinkTimer_timeout():
	visible = !visible
	blinkTarget.visible = visible

func _on_TIE_enter_break():
	start()
	
func _on_TIE_resume_break():
	stopBlinking()

func _on_TIE_buff_end():
	stopBlinking()


func _on_TIE_buff_cleared():
	stopBlinking()
