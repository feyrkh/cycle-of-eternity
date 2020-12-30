extends Node
class_name ExemplarData

const statsTree = {
	'str':{
		'bone': ['armBoneStr', 'legBoneStr', 'skullBoneStr', 'coreBoneStr'],  # bone density
		'muscle': ['armStr', 'legStr', 'gripStr', 'coreStr'], # muscle strength (how much force you can exert)
		'endurance': ['armEnd', 'legEnd', 'gripEnd', 'coreEnd', 'fatigue'], # muscle endurance (how much muscle fatigue you can handle)
		'b_recover': ['fatigueRecover', 'woundRecover'], # recovery speed
	},
	'agi':{
		'speed': ['moveSpd', 'attackSpd', 'reactSpd'], # speed of actions
		'dexterity': ['jumpAgi', 'attackAgi', 'defendAgi'], # effectiveness of different actions
	},
	'int':{
		'ability': ['perceive', 'insight', 'synthesis', 'propriception'], # mental abilities
		'focus': ['thinkSpeed', 'multitask'], # related to mental foci
		'skill': ['musicInt', 'mathInt', 'spatialInt', 'languageInt', 'emotionalInt'], # ability in different intellectual domains
		'm_recover': ['focusRecovery'] # recovery speed
	},
	'will':{
		'mind': [
			'emptyMind',  # ability to clear your mind, reduce time needed for meditation?
			'focus', # amount of energy available for mental feats
			'resistManipulation', 'resistConfusion'], # resist mental
		'body': ['resistFatigue', 'resistDisorient'], # resist physical
		'soul': ['spiritFatigue', 'spiritRecover', 
			'resistDomination', ''] # resist spiritual
	}
}

var entityId
var entityName
var stats = {}
var gender
var organizerData

func set_entity_name(newName): 
	entityName = newName
	organizerData.friendlyName = newName

func get_entity_name(): return entityName

func get_organizer_name():
	return 'exemplar_'+str(entityId)

func serialize():
	var retval = {'cmd':'exemplar', 'dt':Util.DATATYPE_EXEMPLAR, 'g':gender, 'name':entityName, 'id':entityId, 'stats':stats, }
	return retval

func deserialize(data):
	#init_from_file(data['f'])
	entityId = data.get('id', 0)
	organizerData = GameState.get_organizer_data(get_organizer_name())
	entityName = data.get('name', 'Unnamed Exemplar')
	stats = data.get('stats', {})
	gender = data.get('g', 'f')
	for statsTreeName in statsTree:
		var avgStats = get_stats_summary(statsTree.get(statsTreeName))['mean']
		checkMissingStats(statsTree.get(statsTreeName), avgStats)


func on_resource_create(newName, createOpts, entityId):
	self.entityId = entityId
	
	var defaultMed = 50
	var defaultStdev = 16.6
	
	map_reduce_stats_tree(statsTree['str'], {}, '_generate_stats_array', '_no_op_reduce', '', {'med':createOpts.get('strMed', defaultMed), 'stdev':createOpts.get('strStdev', defaultStdev), 'rigor':createOpts.get('rigor', 1)})
	map_reduce_stats_tree(statsTree['agi'], {}, '_generate_stats_array', '_no_op_reduce', '', {'med':createOpts.get('dexMed', defaultMed), 'stdev':createOpts.get('dexStdev', defaultStdev), 'rigor':createOpts.get('rigor', 1)})
	map_reduce_stats_tree(statsTree['int'], {}, '_generate_stats_array', '_no_op_reduce', '', {'med':createOpts.get('intMed', defaultMed), 'stdev':createOpts.get('intStdev', defaultStdev), 'rigor':createOpts.get('rigor', 1)})
	map_reduce_stats_tree(statsTree['will'], {}, '_generate_stats_array', '_no_op_reduce', '', {'med':createOpts.get('willMed', defaultMed), 'stdev':createOpts.get('willStdev', defaultStdev), 'rigor':createOpts.get('rigor', 1)})
	gender = createOpts.get('gender', Util.rand_choice(['m', 'f']))
	# ignoring newName
	entityName = NameGenerator.generate('disciple_'+gender)

func _generate_stats_array(statNameArray, statPrefix, opts):
	for statName in statNameArray:
		generate_stat(statName, opts['med'], opts['stdev'], opts.get('rigor'))

func _no_op_reduce(prevSummary, newSummary, statPrefix, opts):
	return prevSummary

func generate_stat(statName, median, stdev, percentileRetries):
	var valuePercent = 0
	for i in percentileRetries:
		var p = randf()
		#print('percentile: ', p)
		if p > valuePercent: valuePercent = p
	var value = Util.bell_curve(median, stdev, valuePercent)
	stats[statName] = value
	var maxValue = (Util.bell_curve(0.3, 0.075, randf()) + 1) * value
	if maxValue < value: maxValue = value
	stats['max_'+statName] = maxValue
	
func on_organizer_entry_clicked(orgEntryNode):
	print('opening disciple: ', entityName)
	print(stats)	
	var popup = load("res://exemplar/exemplar.tscn").instance()
	popup.sourceData = self
	if orgEntryNode: popup.orgEntryNode = orgEntryNode
	GameState.add_inner_panel_popup(popup)

func map_reduce_stats_tree(tree, baseData:Dictionary, mapFuncName, reduceFuncName, statPrefix='', opts={}):
	var summary = baseData.duplicate()
	if tree is Dictionary:
		for k in tree:
			var v = tree[k]
			if v is Dictionary:
				var subSummary = map_reduce_stats_tree(v, baseData, mapFuncName, reduceFuncName, statPrefix, opts)
				summary = call(reduceFuncName, summary, subSummary, statPrefix, opts)
			else: # value is an array of stat names
				var subSummary = call(mapFuncName, v, statPrefix, opts)
				summary = call(reduceFuncName, summary, subSummary, statPrefix, opts)
	elif tree is Array:
		return call(mapFuncName, tree, statPrefix, opts)
	return summary

func get_stat(statName):
	return stats.get(statName, 0)

func get_stats_summary(statsTree, statPrefix=''):
	if statsTree is String:
		if statsTree == '':
			statsTree = self.statsTree
		else:
			var chunks = statsTree.split('.', false)
			statsTree = self.statsTree
			for i in chunks.size() - 1:
				var chunk = chunks[i]
				var nextStep = statsTree.get(chunk, {})
				if nextStep is Dictionary or nextStep is Array: statsTree = nextStep
				else: 
					printerr("Invalid stats path when getting summary: ", statsTree)
					return {'sum':0,'count':0,'mean':0}
			var lastStep = chunks[chunks.size()-1]
			if statsTree is Array: return {'sum':get_stat(lastStep),'count':1,'mean':get_stat(lastStep)}
			else: statsTree = statsTree.get(lastStep)
	return map_reduce_stats_tree(statsTree, {'sum':0,'count':0,'mean':0}, '_avg_stats_array', '_combine_avg_map', statPrefix)

func _avg_stats_array(statNameArray, statPrefix, opts):
	var count = 0
	var sum = 0
	for statName in statNameArray:
		var statValue = stats.get(statPrefix+statName)
		if statValue != null:
			sum += statValue
			count += 1
	if count == 0: return {'sum':0,'count':0,'mean':0}
	return {'sum':sum, 'count':count, 'mean':sum/count}

# combine to get average across all stats - not what we want, instead should average the rollup scores only, so sections with many subcomponents don't overwhelm less populous sections
#func _combine_avg_map(prevSummary, newSummary, statPrefix, opts):
#	var result = {'count':prevSummary.get('count',0) + newSummary.get('count', 0), 'sum': prevSummary.get('sum', 0) + newSummary.get('sum', 0)}
#	result['mean'] = result['sum']/result['count']
#	return result
func _combine_avg_map(prevSummary, newSummary, statPrefix, opts):
	var result = {'count':prevSummary.get('count',0) + 1, 'sum': prevSummary.get('sum', 0) + newSummary.get('mean', 0)}
	if result['count'] == 0: result['mean'] = 0
	else: result['mean'] = result['sum']/result['count']
	return result
	
#func get_stats_summary(statsTree):
#	var summary = {'sum':0,'count':0,'mean':0}
#	for k in statsTree:
#		var v = statsTree[k]
#		if v is Dictionary:
#			var subSummary = get_stats_summary(statsTree)
#			summary['sum'] = summary['sum'] + subSummary['sum']
#			summary['count'] = summary['count'] + subSummary['count']
#			summary['mean'] = summary['sum']/summary['count']
#		else: # value is an array of stat names
#			var sum = 0
#			var count = 0
#			for statName in v:
#				var statValue = stats.get(statName)
#				if statValue != null:
#					count += 1
#					sum += statValue
#			return {'sum':sum,'count':count,'mean':sum/count}
			
	
func checkMissingStats(statsTree, expectedAmt):
	pass

func init_from_file(filename):
	self.filename = filename
	var file = File.new()
	file.open(filename, file.READ)
	var text = file.get_as_text()
	file.close()
	var baseData = parse_json(text)

