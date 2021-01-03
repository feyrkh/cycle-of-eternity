extends Node2D
onready var placedItems = find_node('PlacedItems')
onready var hoverItems = find_node('HoverItems')

func _ready():
	Event.connect("new_scene_loaded", self, 'on_new_scene_loaded')
	Event.connect('place_item', self, 'on_place_item')
	Event.connect('finalize_place_item', self, 'on_finalize_place_item')
	Event.connect('restore_item_placement', self, 'on_restore_item_placement')
	Event.connect('clear_item_placement', self, 'on_clear_item_placement')
	if GameState.loadingSaveFile:
		GameState.load_world(GameState.loadingSaveFile)
		GameState.loadingSaveFile = null
	if GameState.bootstrapScene:
		on_new_scene_loaded(GameState.bootstrapScene)
	
func on_new_scene_loaded(newScene):
	if newScene.has_method('setupNewScene'):
		newScene.setupNewScene($UI, self)
	Util.clear_children($CurScene)
	Util.clear_children(placedItems)
	Util.clear_children(hoverItems)
	$CurScene.add_child(newScene)

func on_place_item(itemShadow, itemData, sourceNode):
	if itemShadow.get_parent() != null:
		itemShadow.get_parent().remove_child(itemShadow)
	if itemData.get('hover'):
		hoverItems.add_child(itemShadow)
	else:
		placedItems.add_child(itemShadow)
	itemShadow.position = OS.get_window_size()/2
	Input.warp_mouse_position(itemShadow.global_position)
	Conversation.clear()
	Conversation.speaking(null)
	Conversation.run()

func on_clear_item_placement():
	Util.clear_children(hoverItems)
	Util.clear_children(placedItems)

func on_restore_item_placement(itemData, hover):
	var posX = itemData.get('posX')
	var posY = itemData.get('posY')
	var img = itemData.get('img')
	if !posX or !posY or !img: return
	var scaleX = itemData.get('scaleX', 1)
	var scaleY = itemData.get('scaleY', 1)
	var rot = itemData.get('rot', 0)
	var sprite = Sprite.new()
	sprite.texture = load(img)
	sprite.position = Vector2(posX, posY)
	sprite.scale = Vector2(scaleX, scaleY)
	sprite.rotation = rot
	itemData['spriteName'] = sprite.name
	if itemData.get('hover'):
		hoverItems.add_child(sprite)
	else:
		placedItems.add_child(sprite)

func on_finalize_place_item(position, scale, rotation, itemData, sourceNode):
	var item = Sprite.new()
	item.texture = load(itemData.get('img'))
	item.global_position = position
	item.scale = scale
	item.rotation = rotation
	if itemData.get('hover'):
		hoverItems.add_child(item)
	else:
		placedItems.add_child(item)
	if itemData.has('produce'): itemData['active'] = true
