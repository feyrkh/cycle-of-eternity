extends Node2D

func _on_NewGame_pressed():
	GameState.bootstrapScene = load('res://scene/tutorial.tscn').instance()
	get_tree().change_scene("res://GameScene.tscn")
	
