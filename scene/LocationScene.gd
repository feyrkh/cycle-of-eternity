extends Node2D
class_name LocationScene

var UI
var GameScene

func _ready():
	setup_base()
	if !setup_quest(): setup_default()

func setup_base():
	pass

func setupNewScene(ui, gameScene):
	self.UI = ui
	self.GameScene = gameScene

func setup_default():
	pass

func setup_quest():
	#if GameState.quest.get('placeholder') == 'condition':
	#	return true
	return false
