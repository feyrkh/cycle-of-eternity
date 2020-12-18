extends Node2D

func _ready():
	Event.connect("new_scene_loaded", self, 'on_new_scene_loaded')
	if GameState.loadingSaveFile:
		GameState.load_world(GameState.loadingSaveFile)
		GameState.loadingSaveFile = null
	if GameState.bootstrapScene:
		on_new_scene_loaded(GameState.bootstrapScene)
	
func on_new_scene_loaded(newScene):
	if newScene.has_method('setupNewScene'):
		newScene.setupNewScene($UI, self)
	$CurScene.add_child(newScene)
