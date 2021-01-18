extends Node

const Q_COMPLETE="done"

# Startup quest - visit your office, give an order, see it in your outbox, pass time, see your inbox
const Q_TUTORIAL='tutorial' 
const Q_TUTORIAL_OFFICE='tutorial_office' # first arrival in your office
const Q_TUTORIAL_PLACE_DESK='tutorial_placeDesk' # placing your furniture
const Q_TUTORIAL_FIRST_DECREE='tutorial_firstDecree' # first decree has been drafted
const Q_TUTORIAL_DISCARD_RUBBISH='tutorial_discardRubbish' # asked to discard trash
const Q_TUTORIAL_PASS_TIME='tutorial_passTime' # asked to pass time
const Q_TUTORIAL_BUILD_TRAINING='tutorial_buildTraining' # build a training hall
const Q_TUTORIAL_WAIT_FOR_TRAINING_HALL='tutorial_waitForTraining' # wait for training hall to be completed
const Q_TUTORIAL_INSTALL_EQUIPMENT='install_training' # install training equipment in the training hall
const Q_TUTORIAL_OBTAIN_DISCIPLE='obtain_disciple' # go to the training hall to get a free disciple
const Q_TUTORIAL_TRAIN_DISCIPLE='train_disciple' # set up a training program
const Q_TUTORIAL_QUEUE_TRAINING='queue_training'
const Q_TUTORIAL_SPAR_ATTACK='spar_attack'
const Q_TUTORIAL_SPAR_DEFEND='spar_defend'

# Basics of attacking
const Q_COMBAT_A='combatA'
const Q_COMBAT_A_ACTIVE="combatA_active"
const Q_COMBAT_A_MOVE_COMBATANT="combatA_moveCombatant"
const Q_COMBAT_A_FOCUS_TARGET="combatA_focusTarget"
const Q_COMBAT_A_SELECT_EXEMPLAR="combatA_selectExemplar"
const Q_COMBAT_A_SELECT_ATTACK="combatA_selectAttack"
const Q_COMBAT_A_PLACE_ATTACK="combatA_placeAttack"
const Q_COMBAT_A_UNPAUSE="combatA_unpause"
const Q_COMBAT_A_EXIT_COMBAT="combatA_exitCombat"

const Q_COMBAT_B_ACTIVE="combatB_active"



const QuestNames = {
	Q_TUTORIAL: "Introduction",
	Q_COMBAT_A: "Basics of attacking",
}

const QuestDescriptions = {
	Q_TUTORIAL_OFFICE: "Go to your office - find it in the left-hand organizer",
	Q_TUTORIAL_PLACE_DESK: "Find your packed-up desk on the right and place it in your office",
	Q_TUTORIAL_FIRST_DECREE: "Review the decree in your outbox",
	Q_TUTORIAL_DISCARD_RUBBISH: "Click the discarded decrees to read them if you like, then drag them into the trash can to dispose of them",
	Q_TUTORIAL_PASS_TIME: "Pass time until the decree is complete by clicking the hourglass, pressing one of the time speed buttons above it, or pressing spacebar to unpause",
	Q_TUTORIAL_WAIT_FOR_TRAINING_HALL: "Build a training hall using the decree template in the left-hand organizer - a new decree will appear in your outbox. Then pass time until the training hall is completed.",
	Q_TUTORIAL_INSTALL_EQUIPMENT: "Visit the training hall and install training equipment",
	Q_TUTORIAL_TRAIN_DISCIPLE: "Click on {helperName} in your New Arrivals folder in the left-hand organizer to open her status page",
	Q_TUTORIAL_QUEUE_TRAINING: "Select a type of training, then click 'Add to Plan' it to her training plan - set up as many as you like!\nMake sure you're in the location you want to train - it makes a difference.",
	Q_TUTORIAL_SPAR_ATTACK: "Use the attack dummy in the training hall to learn how to attack",
	Q_TUTORIAL_SPAR_DEFEND: "Use the defense dummy in the training hall to learn how to defend",
	
	Q_COMBAT_A_MOVE_COMBATANT: "Click & drag to move a combatant",
	Q_COMBAT_A_FOCUS_TARGET: "Click & drag a target icon to create an attack line to an opponent",
	Q_COMBAT_A_SELECT_EXEMPLAR: "Click to select your exemplar and review their combat techniques",
	Q_COMBAT_A_SELECT_ATTACK: "Click on an attack technique (with a sword next to it), or press the hotkey (the number in parentheses) to begin an attack. Hotkeys are assigned in numerical order each time the organizer is loaded, so they can be changed by rearranging your techniques.",
	Q_COMBAT_A_PLACE_ATTACK: "Hover your selected technique over your half of the attack line. The gray segment at the end of the attack represents loss of balance - the closer you place the attack to your opponent on the timeline, the more unbalanced you will be.",
	Q_COMBAT_A_UNPAUSE: "Press spacebar or use the time controls to unpause time",
	Q_COMBAT_A_EXIT_COMBAT: "Destroy all of your opponents, or right-click to deselect your exemplar and use the combat menu on the right to exit combat",


}
