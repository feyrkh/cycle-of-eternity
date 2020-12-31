extends Resource
class_name TrainingData

export(String) var name:String
export(String) var description:String
export(Dictionary) var traineeRequirement:Dictionary # {'min':60,'max':1000}
# for statImprove, choose random number from 0..max(stat)
export(Dictionary) var statImprove:Dictionary # {'c': chances, 'm': multiplier}
# for fatigue, choose random number from 0..difficulty. If > 0..resist, then apply 0.1 fatigue * multiplier; repeat 'chances' times
export(Dictionary) var fatigue:Dictionary # {'c': chances, 'm': multiplier, 'd': difficulty, 'r': resistStatName}

const DEFAULT_CHANCES = 1
const DEFAULT_MULTIPLIER = 0.1
const DEFAULT_FATIGUE_MULTIPLIER = 10
const DEFAULT_DIFFICULTY = 200
const DEFAULT_RESIST_FATIGUE_STAT = "resistFatigue"

func get_summary():
	var summary = ''
	if traineeRequirement.size() > 0:
		summary = summary + '\nRequirements:\n'
		var friendlyMap = {}
		for k in traineeRequirement:
			friendlyMap[Util.get_stat_friendly_name(k)] = traineeRequirement[k]
		var friendlyKeys = friendlyMap.keys()
		friendlyKeys.sort()
		for k in friendlyKeys:
			var line
			if friendlyMap[k].has('min') and friendlyMap[k].has('max'):
				line = '   %s between %.1f and %.1f\n' % [k, friendlyMap[k]['min'], friendlyMap[k]['max']]
			elif friendlyMap[k].has('min'):
				line = '   %s greater than %.1f\n' % [k, friendlyMap[k]['min']]
			elif friendlyMap[k].has('max'):
				line = '   %s less than %.1f\n' % [k, friendlyMap[k]['max']]
			summary += line
		summary += '\n'
		
	if statImprove.size() > 0:
		summary = summary + '\nBenefits:\n'
		var friendlyMap = {}
		for k in statImprove:
			friendlyMap[Util.get_stat_friendly_name(k)] = statImprove[k]
		var friendlyKeys = friendlyMap.keys()
		friendlyKeys.sort()
		for k in friendlyKeys:
			var chanceText
			var chances = friendlyMap[k].get('c', DEFAULT_CHANCES)
			if chances < 1: chanceText = 'an occasional chance'
			elif chances < 2: chanceText = '1 chance'
			else: chanceText = '%d chances'%chances
			var line = "   %s - %s to increase by %.1f\n" % [k, chanceText, friendlyMap[k].get('m', DEFAULT_MULTIPLIER)]
			summary += line
		summary += '\n'
		
	if fatigue.size() > 0:
		summary = summary + '\nDrawbacks:\n'
		var friendlyMap = {}
		for k in fatigue:
			friendlyMap[Util.get_stat_friendly_name(k)] = fatigue[k]
		var friendlyKeys = friendlyMap.keys()
		friendlyKeys.sort()
		for k in friendlyKeys:
			var chanceText
			var chances = friendlyMap[k].get('c', DEFAULT_CHANCES)
			if chances < 1: chanceText = 'An occasional chance'
			elif chances < 2: chanceText = '1 chance'
			else: chanceText = '%d chances'%chances
			var line = "   %s to decrease %s by %.1f, resisted with difficulty %d by '%s'\n" % [chanceText, k, friendlyMap[k].get('m', DEFAULT_MULTIPLIER), friendlyMap[k].get('d', DEFAULT_DIFFICULTY), Util.get_stat_friendly_name(friendlyMap[k].get('r', DEFAULT_RESIST_FATIGUE_STAT))]
			summary += line
		summary += '\n'
	
	return summary
		
		
func serialize():
	return {
		'name': name,
		'description': description,
		'statImprove': statImprove,
		'requirements': traineeRequirement,
		'fatigue': fatigue
	}

func deserialize(json):
	self.name = json.get('name', 'Unnamed training')
	self.description = json.get('description', 'Indescribable training')
	self.statImprove = json.get('statImprove', {})
	self.traineeRequirement = json.get('requirements',{})
	self.fatigue = json.get('fatigue', {})

#func load_location_modifications(locationOrganizerName):
#	var orgData = GameState.get_organizer_data(locationOrganizerName)
#	for entry in orgData.entries:
#		if !entry.data: 
#			continue
#		if entry.data is Dictionary:
#			var entryData = entry.data
#			if entryData.get('cmd', '') != 'trainEquip': 
#				continue
#			var trainData = entryData.get('train')
#			if !trainData: 
#				continue
#			if trainData.get('name') != self.name: 
#				continue
#			description += '\n'+trainData.get('trainMsg', "Enhanced with the use of %s.\n"%[entry.name])
#			var statImprove = trainData.get('statImprove',{})
#			var traineeRequirement = trainData.get('traineeRequirement', {})
#			var fatigue = trainData.get('fatigue', {})
#			Util.merge_maps(self.statImprove, statImprove)
#			Util.merge_maps(self.traineeRequirement, traineeRequirement)
#			Util.merge_maps(self.fatigue, fatigue)

func exemplar_can_train(exemplarData):
	for k in traineeRequirement:
		var minAllowed = traineeRequirement[k].get('min',0)
		var maxAllowed = traineeRequirement[k].get('max',Util.MAX_INT)
		var cur = exemplarData.get_stat(k)
		if cur < minAllowed:
			return '%s is too low - need more than %.1f for this training to be effective.'%[Util.get_stat_friendly_name(k), minAllowed]
		if cur > maxAllowed:
			return '%s is too high - need less than %.1f for this training to be effective.'%[Util.get_stat_friendly_name(k), minAllowed]
	for k in fatigue:
		if exemplarData.get_stat(k) <= 0:
			return '%s is too low - need more than 0 for this training to be effective.'%[Util.get_stat_friendly_name(k)]
	return true

func train_exemplar(exemplarData):
	for k in statImprove:
		var curLevel = exemplarData.get_stat(k)
		var maxLevel = exemplarData.get_stat_max(k)
		var trainCount = statImprove[k].get('c', DEFAULT_CHANCES)
		if trainCount < 1 and trainCount > 0: 
			if randf()<trainCount: 
				trainCount = 1
			else: 
				continue
		var trainMultiplier = statImprove[k].get('m', DEFAULT_MULTIPLIER)
		for i in trainCount:
			var chance = randf()*maxLevel
			if chance > curLevel: 
				curLevel = curLevel + (0.01*trainMultiplier)
		exemplarData.set_stat(k, curLevel)	
	for k in fatigue:
		var curLevel = exemplarData.get_stat(k)
		var fatigueCount = fatigue[k].get('c', DEFAULT_CHANCES)
		if fatigueCount < 1 and fatigueCount > 0: 
			if randf()<fatigueCount: 
				fatigueCount = 1
			else: 
				continue
		var fatigueMultiplier = fatigue[k].get('m', DEFAULT_FATIGUE_MULTIPLIER)
		var fatigueResist = exemplarData.get_stat(fatigue[k].get('r', DEFAULT_RESIST_FATIGUE_STAT), 50)
		var fatigueDifficulty = fatigue[k].get('d', DEFAULT_DIFFICULTY)
		for i in fatigueCount:
			var fatigueDmg = randf()*fatigueDifficulty
			var fatigueHeal = randf()*fatigueResist
			if fatigueDmg >= fatigueHeal:
				curLevel = curLevel - (0.01*fatigueMultiplier)
		exemplarData.set_stat(k, curLevel)
