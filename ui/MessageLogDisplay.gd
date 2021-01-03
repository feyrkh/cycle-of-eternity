extends PanelContainer

const PAUSE_CATEGORIES = ['training_problem', 'decree_complete']

var mouseIsOver
var start
var end
var curProgress
var waitingForClose = null

onready var msgLabel = find_node("MessageLabel")


func on_special_event(msgData, category):
	open()
	if PAUSE_CATEGORIES.has(category):
		Event.emit_signal("time_should_pause")
		
	msgLabel.text += "\n%s %s"%[Calendar.get_formatted_date(), msgData]
	if msgLabel.get_line_count() > 100: 
		var chunks = msgLabel.text.split("\n", false, 1)
		msgLabel.text = chunks[chunks.size()-1]


func _ready():
	Event.connect("special_event", self, "on_special_event")
	Event.connect("save_state_loaded", self, "on_save_state_loaded")
	get_tree().root.find_node('DragSurface', true, false).connect('resized', self, 'on_resize')
	on_resize()
	set_process(false)
	rect_position.y = (-rect_size.y) + 10
	close()

func open():
	set_process(true)
	waitingForClose = null
	start = -rect_size.y
	end = 0
	curProgress = 1+(rect_position.y/rect_size.y)  # -100/400 = -0.25; 1+(-0.25) = 0.75; 75% done moving from -400 to 0

func _process(delta):
	if mouseIsOver and end < 0: 
		open()
		return
	curProgress += delta*2
	if curProgress > 1: 
		curProgress = 1
	self.rect_position.y = lerp(start, end, curProgress)
	if curProgress == 1:
		if end == 0: # currently opening
			if waitingForClose == null: # just finished opening
				waitingForClose = 1.5
			else: # waiting a few seconds before closing
				waitingForClose -= delta
				if waitingForClose <= 0: # time's up
					close()
		else: # currently closing
			pass
			#set_process(false) # no need to keep processing, since we are fully closed now - we'll restart processing later when we need to open again

func close():
	set_process(true)
	start = 0 # -100
	end = (-rect_size.y) + 10 # -400
	curProgress = -(rect_position.y/rect_size.y) # -100/400 = -0.25; -(-0.25) = 0.25; 25% done moving from 0 to -400

func get_message_history():
	return msgLabel.text

func set_message_history(val):
	msgLabel.text = val

func on_resize():
	var target = get_tree().root.find_node('DragSurface', true, false)
	if !target: return
	self.rect_size = Vector2(target.rect_size.x, 0)
	self.rect_global_position.x = target.rect_global_position.x
	
func _on_RichTextLabel_mouse_entered():
	mouseIsOver = true

func _on_RichTextLabel_mouse_exited():
	mouseIsOver = false
	
func on_save_state_loaded():
	#msgLabel.text = ""
	pass
