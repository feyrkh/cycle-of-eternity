extends PopupPanel

onready var itemImage:TextureRect = find_node('ItemImage', true)
onready var itemText:Label = find_node('ItemText', true)

var hasImage = false

func set_text(msg):
	itemText.text = msg
	update_rect_size()

func set_image(imgFile):
	itemImage.texture = load(imgFile)
	hasImage = true
	update_rect_size()
	
func _on_MsgPopup_popup_hide():
	queue_free()

func _ready():
	if get_parent() == get_tree().root: popup()
	update_rect_size()

func update_rect_position():
	var screenCenter = get_viewport_rect().size / 2
	var halfSize = rect_size / 2
	rect_global_position = screenCenter - halfSize
	#rect_global_position.y = screenCenter.y - halfSize.y
	rect_global_position.y = 10

func update_rect_size():
	self.rect_size.x = itemText.rect_global_position.x - rect_global_position.x + 20
	self.rect_size.y = max(itemText.rect_global_position.y - rect_global_position.y, itemImage.rect_global_position.y - rect_global_position.y) + 20
	#print('grid.x=', decreeOptionsGrid.rect_global_position.x, '; popup.x=',  rect_global_position.x, '; grid.size.x=', decreeOptionsGrid.rect_size.x)
	#visible = true
	update_rect_position()

func _on_MsgPopup_about_to_show():
	update_rect_size()
