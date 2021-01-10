extends PanelContainer

var questListLabel
var unreadIcon
var isOpen = true
var originalHeight

func _ready():
	questListLabel = find_node('QuestListLabel')
	unreadIcon = find_node('UnreadIcon')
	render_active_quests()
	originalHeight = rect_min_size.y
	Event.connect("quest_state_changed", self, "on_quest_state_changed")
	Event.connect("new_scene_loaded", self, "on_new_scene_loaded")

func on_quest_state_changed(questName, oldState, newState):
	render_active_quests()

func on_new_scene_loaded(newScene):
	render_active_quests()

func render_active_quests():
	var oldText = questListLabel.text
	var newText = ''
	for questName in GameState.get_active_quests():
		newText = newText + generate_quest_description(questName)
	newText = newText.trim_suffix('\n')
	questListLabel.text = newText.format(GameState.settings)
	if !isOpen and newText != oldText:
		unreadIcon.visible = true
	self.visible = newText != ''

func generate_quest_description(questName):
	var title = Quest.QuestNames.get(questName)
	var desc = Quest.QuestDescriptions.get(GameState.get_quest_status(questName), '')
	if !title or !desc: 
		return ''
	return "%s: %s\n"%[title, desc]

func _on_TextureButton_toggled(button_pressed):
	if !button_pressed:
		rect_min_size.y = originalHeight
	else:
		rect_min_size.y = 22
