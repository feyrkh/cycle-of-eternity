extends LocationScene

# Any setup commands that will always run before the quest or default room setup - don't forget to call .setup_base()
func setup_base():
	.setup_base()
	UI.load_right_organizer('office')

# Any setup commands for the room if there is no active quest that's overriding things - 
func setup_default():
	pass

# Check for any important quest states and setup as needed, may call setup_default() manually as well if needed
func setup_quest():
	if GameState.quest.get(Quest.Q_TUTORIAL) == Quest.Q_TUTORIAL_OFFICE:
		var c = Conversation
		c.speaking('helper')
		c.text("""
This will be your office, {playerName}. From here you will administer the new school of the sacred arts - making personnel decisions, reviewing resource allocations, sending decrees, and receiving updates from your subordinates.

I have taken the liberty of drawing up your first decree - the drafting of a work party from the nearby villages. With these workers we can get started on the infrastructure we need to support our studies into the sacred arts.

Please take a look at your outbox to the right, where you will find the decree. Any decrees in your outbox at the end of the week will be carried out!'
""")
		c.cmd(self, 'setup_first_decree')
		yield(c.run(), 'completed')
		GameState.quest[Quest.Q_TUTORIAL] = Quest.Q_TUTORIAL_FIRST_DECREE
		c.page('')
		c.speaking(null)
		c.clear()
		yield(c.run(), 'completed')
		return true # Make any changes you need here...
	return .setup_quest()

func setup_first_decree():
	var officeOrg = load("res://ui/organizer/OrganizerData.gd").new()
	officeOrg.add_entry('Outbox:noEdit:isOpen/Work Orders:noEdit:isOpen/Raise Work Crew', 
		{'order':'newWorkCrew'}, 'tutorialFirstWorkOrder')
	officeOrg.add_entry('Inbox:noEdit/From the Emperor/Your mission', {'cmd':'msg', 'msg':"""
From the office of the Radiant Emperor -

1. By the Emperor's writ and seal, the bearer of this document is authorized and commanded to develop a school for the study and development of the newly discovered sacred sciences.

2. The terrorist organization known as Penumbra Ascension, having damaged the Shadow Aegis which has protected the the Empire of Humanity for untold millennia, will be brought to heel by our mastery of this new form of warfare. 

3. The cooperation of all loyal subjects of the Empire is required. Notwithstanding this decree, all efforts will be made toward self-sufficiency, that the police and military actions required for the ongoing security of Humanity not be compromised.

4. As the sacred sciences are understood and exemplars are produced, the Emperor will request and require the release of individuals and groups of exemplars as necessary for the security of the realm. Failure to produce results risks shame for the leadership of the new school, suffering for the people of the Empire, and the death of all Humanity at the hands of the divine beasts held back by the failing Shadow Aegis.

You have heard the command of the Radiant Emperor, Protector of Humanity, Nemesis of the Heavens - let his words guide your hands and heart, or may the light of Heaven devour you.
"""})
	officeOrg.add_entry('Inbox:noEdit/History/On Sacred Science', {'cmd':'msg', 'msg':"""
- 
"""})
	GameState.add_organizer('office', officeOrg)
	UI.rightOrganizer.refresh_organizer_data(GameState.get_organizer_data('office'))
	yield(get_tree(), 'idle_frame')
	var workorder = UI.rightOrganizer.get_entry_by_id('tutorialFirstWorkOrder')
	workorder.call_attention()
