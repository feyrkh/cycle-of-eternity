extends Node2D

func _on_NewGame_pressed():
	GameState.bootstrapScene = load('res://scene/tutorial.tscn').instance()
	GameState.settings['curSceneName'] = 'tutorial'
	GameState.settings['curSceneSettings'] = {}
	get_tree().change_scene("res://GameScene.tscn")
	
func _on_Continue_pressed():
	GameState.loadingSaveFile = 'quicksave'
	get_tree().change_scene("res://GameScene.tscn")

func _ready():
	var dataValidator = load("res://DataValidator.gd").new()
	dataValidator.validate_all()
