extends Node

var combatant

# map of named moves that can be combined into sequences
# each value is JSON to be deserialized into an AttackTechnique
# Ex:
#      "moves": {
#         "Wooden Block": {
#            "block": true,
#            "attack": false,
#            "cost": {"fatigue":20},
#            "segments": [
#               {
#                  "t": "block",
#                  "l": 0.3,
#                  "d": 1,
#                  "s": {
#                     "defense": 1
#                  }
#               }
#            ]
#         },
#         "idle": {
#            "block": true,
#            "attack": false,
#            "cost": {},
#            "segments": [
#               {
#                  "t": "",
#                  "l": 0.2
#               }
#            ]
#         }
#      },

var moves

var autoAttack = []
var autoDefense = []

var defaultUpdateMoveIntervalSeconds = 1
var updateMoveCounter = 0
var aggroByLine = {}
var autoAttackByLine = {}
var autoDefenseByLine = {}

var tmpStats = {}
var maxFatigue = 50
var autoDefendFatigue = 0
var maxAutoDefendFatigue = 0
var attackFatigue = 50
var maxAttackFatigue = 50
var autoAttackFatigue = 0
var maxAutoAttackFatigue = 0
var autoDefendFatiguePercent = 0 setget set_auto_defend_fatigue_percent
var autoAttackFatiguePercent = 0 setget set_auto_attack_fatigue_percent
var fatigueRecover = 50
var attackFatigueRecover = 0
var autoAttackFatigueRecover = 0
var autoDefendFatigueRecover = 0
var health = 50
var maxHealth = 50
var healthRecover = 0

var attackAggroGrowthPerSecond = 1.0
var defendAggroGrowthPerSecond = 1.0

func set_auto_defend_fatigue_percent(val):
	if val < 0: val = 0
	if val + autoAttackFatiguePercent > 1.0: 
		val = 1.0 - autoAttackFatiguePercent
	autoDefendFatiguePercent = val
	maxAttackFatigue = (1.0 - (autoAttackFatiguePercent + autoDefendFatiguePercent)) * maxFatigue
	maxAutoDefendFatigue = maxFatigue * val
	var excessFatigue = max(0, autoDefendFatigue - maxAutoDefendFatigue)
	autoDefendFatigue -= excessFatigue
	autoAttackFatigue += excessFatigue * autoAttackFatiguePercent
	excessFatigue += max(0, autoAttackFatigue - maxAutoAttackFatigue)
	autoAttackFatigue -= excessFatigue
	attackFatigue += excessFatigue
	excessFatigue = max(0, attackFatigue - maxAttackFatigue)
	attackFatigue -= excessFatigue
	autoDefendFatigue += excessFatigue
	
	autoAttackFatigue = min(autoAttackFatigue, maxAutoAttackFatigue)
	autoDefendFatigue = min(autoDefendFatigue, maxAutoDefendFatigue)
	attackFatigue = min(attackFatigue, maxAttackFatigue)
	autoAttackFatigueRecover = fatigueRecover * autoAttackFatiguePercent
	autoDefendFatigueRecover = fatigueRecover * autoDefendFatiguePercent
	attackFatigueRecover = fatigueRecover * (1.0 - (autoAttackFatiguePercent + autoDefendFatiguePercent))

func set_auto_attack_fatigue_percent(val):
	if val < 0: val = 0
	if val + autoDefendFatiguePercent > 1.0: 
		val = 1.0 - autoDefendFatiguePercent
	autoAttackFatiguePercent = val
	maxAttackFatigue = (1.0 - (autoAttackFatiguePercent + autoDefendFatiguePercent)) * maxFatigue
	maxAutoAttackFatigue = maxFatigue * val
	var excessFatigue = max(0, autoAttackFatigue - maxAutoAttackFatigue)
	autoAttackFatigue -= excessFatigue
	autoDefendFatigue += excessFatigue * autoDefendFatiguePercent
	excessFatigue += max(0, autoDefendFatigue - maxAutoDefendFatigue)
	autoDefendFatigue -= excessFatigue
	attackFatigue += excessFatigue
	excessFatigue = max(0, attackFatigue - maxAttackFatigue)
	attackFatigue -= excessFatigue
	autoAttackFatigue += excessFatigue
	
	autoAttackFatigue = min(autoAttackFatigue, maxAutoAttackFatigue)
	autoDefendFatigue = min(autoDefendFatigue, maxAutoDefendFatigue)
	attackFatigue = min(attackFatigue, maxAttackFatigue)
	autoAttackFatigueRecover = fatigueRecover * autoAttackFatiguePercent/10.0
	autoDefendFatigueRecover = fatigueRecover * autoDefendFatiguePercent/10.0
	attackFatigueRecover = fatigueRecover * (1.0 - (autoAttackFatiguePercent + autoDefendFatiguePercent))/10.0

func _process(delta):
	delta = delta * Calendar.combatSpeed
	updateMoveCounter += delta

	for line in combatant.incomingTargetLines:
		adjust_aggro(line, defendAggroGrowthPerSecond*delta)
	for line in combatant.outgoingTargetLines:
		adjust_aggro(line, attackAggroGrowthPerSecond*delta)
		
	for line in aggroByLine:
		var curAggro = aggroByLine.get(line, 0)
		aggroByLine[line] = curAggro - (curAggro * 0.05 * delta)
	attackFatigue = min(attackFatigue + attackFatigueRecover*delta, maxAttackFatigue)
	autoAttackFatigue = min(autoAttackFatigue + autoAttackFatigueRecover*delta, maxAutoAttackFatigue)
	autoDefendFatigue = min(autoDefendFatigue + autoDefendFatigueRecover*delta, maxAutoDefendFatigue)
	health = min(health + healthRecover*delta, maxHealth)

	if updateMoveCounter > defaultUpdateMoveIntervalSeconds:
		updateMoveCounter -= defaultUpdateMoveIntervalSeconds
		do_next_move()
		

func setup(combatant):
	self.combatant = combatant
	maxFatigue = get_stat('fatigue')
	attackFatigue = maxFatigue
	fatigueRecover = get_stat('fatigueRecover')/10.0
	health = get_stat('health')
	healthRecover = get_stat('healthRecover')/10.0
	maxHealth = health
	updateMoveCounter = defaultUpdateMoveIntervalSeconds - 0.001

func deserialize(data):
	moves = data.get('moves', {})
	autoAttack = data.get('autoAttack', [])
	autoDefense = data.get('autoDefense', [])
	set_auto_attack_fatigue_percent(data.get('autoAttackPercent', 0.5))
	set_auto_defend_fatigue_percent(data.get('autoDefendPercent', 0.5))

func sort_lines_by_aggro(a, b):
	return aggroByLine.get(a, 0) > aggroByLine.get(b, 0)

func do_next_move():
	var keys = aggroByLine.keys()
	keys.sort_custom(self, 'sort_lines_by_aggro')
	for chosenLine in keys:
		if chosenLine.sourceCombatant == combatant:
			if do_next_attack(chosenLine): return
		elif chosenLine.targetCombatant == combatant:
			if do_next_block(chosenLine): return

func do_next_attack(attackLine):
	return false

func do_next_block(defenseLine):
	if !autoDefense or autoDefense.size() == 0: 
		var curAggro = aggroByLine.get(defenseLine, 0)
		aggroByLine[defenseLine] = curAggro - (curAggro * 0.1) 
		return false
	var autoDefenseOffset = autoDefenseByLine.get(defenseLine, 0)
	var moveName = autoDefense[autoDefenseOffset]
	var move = moves.get(moveName)
	if !move:
		printerr("Nonexistent move name selected for autoBlock: ", moveName)
		return false
	else:
		return do_technique(defenseLine, move, 0.0, "autoDefendFatigue")

func do_technique(line, move, lineOffset, fatigueType="attackFatigue"):
	var costs = move.get('cost', {})
	for statName in costs:
		var costStatName = statName
		if statName == "fatigue":
			statName = fatigueType
		if get_stat(statName) < costs.get(costStatName):
			return false # not enough of the necessary stat to do this	
	for statName in costs:
		var costStatName = statName
		if statName == "fatigue":
			statName = fatigueType
		adjust_stat(statName, -costs.get(costStatName))
	var tech = load('res://combat/AttackTechnique.tscn').instance()
	tech.combatScene = combatant.combatScene
	tech.sourceCombatant = combatant
	tech.targetLine = line
	tech.currentlyPlacing = false
	if line.sourceCombatant == combatant:
		tech.update_endpoints(line.points[0], line.points[1])
	else:
		tech.update_endpoints(line.points[2], line.points[1])
	tech.deserialize(move)
	tech.setup(lineOffset, combatant)
	combatant.combatScene.techniqueLayer.add_child(tech)
	line.add_technique(tech)
	var powerLevel = tech.get_power_level().get('total', 50)
	adjust_aggro(line, -powerLevel)
	return true

func set_stat(statName, amt):
	match statName:
		"health": health = amt
		"attackFatigue": attackFatigue = amt
		"autoDefendFatigue": autoDefendFatigue = amt
		"autoAttackFatigue": autoAttackFatigue = amt
		"max_health": maxHealth = amt
		"max_fatigue": maxFatigue = amt
		"max_attackFatigue": maxAttackFatigue = amt
		"max_autoDefendFatigue": maxAutoDefendFatigue = amt
		"max_autoAttackFatigue": maxAutoAttackFatigue = amt
		_:
			tmpStats[statName] = amt

func adjust_stat(statName, amt):
	var cur = get_stat(statName)
	set_stat(statName, cur + amt)

func get_stat(statName):
	match statName:
		"health": return health
		"attackFatigue": return attackFatigue
		"autoDefendFatigue": return autoDefendFatigue
		"autoAttackFatigue": return autoAttackFatigue
		"max_health": return maxHealth
		"max_fatigue": return maxFatigue
		"max_attackFatigue": return maxAttackFatigue
		"max_autoDefendFatigue": return maxAutoDefendFatigue
		"max_autoAttackFatigue": return maxAutoAttackFatigue
		_:
			if !tmpStats.has(statName):
				tmpStats[statName] = combatant.get_stat(statName, 0)
			return tmpStats[statName]

func adjust_aggro(line, amount):
	var curAggro = aggroByLine.get(line, 0)
	curAggro = max(0, curAggro + amount)
	aggroByLine[line] = curAggro
