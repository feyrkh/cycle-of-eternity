extends Node

const DecreeData = preload("res://decree/DecreeData.gd")
const projectOrganizers = ['office']
var processingProjects = []
var needToRefresh = false

func _ready():
	Event.connect("pass_time", self, 'on_pass_time')

func on_pass_time(amt):
	reset()
	GameState.save_organizers()
	GameState.produce_resources()
	ProjectProcessor.reset()
	ProjectProcessor.process_consumers()
	ProjectProcessor.process_exemplar_training()
	ProjectProcessor.process_projects()

func reset():
	needToRefresh = false

func complete_decree_project(decreeData:DecreeData):
	needToRefresh = true
	print('completed project: ', decreeData.projectName)

func process_exemplar_training():
	var exemplarEntries = GameState.get_organizer_data('main').get_entries_with_type('exemplar')
	for exemplarEntry in exemplarEntries:
		var exemplarData = exemplarEntry.data
		exemplarData.on_training_start()
		var trainingOrganizerData = ExemplarData.get_training_organizer(exemplarData)
		var entriesToRecycle = []
		if trainingOrganizerData.entries.size() == 0:
			Event.special_event("%s has no training program set!"%exemplarData.entityName, 'training_problem')
		while trainingOrganizerData.entries.size() > 0:
			var trainingPlanEntry = trainingOrganizerData.entries[0]
			var trainingPointer = trainingPlanEntry.data
			# example trainingPointer: {"loc":locationWhereWeAreTraining, "src":organizerContainingTraining, "id":trainingData.id, "count": count, "repeat":repeat}
			# Make sure the training location still exists - if not, recycle the whole entry and mark it as failed, continue loop
			var trainingLocationOrganizerData = GameState.get_organizer_data(trainingPointer.get('loc'))
			if !trainingLocationOrganizerData: 
				trainingPlanEntry.data['error'] = "The training location no longer exists - was the location destroyed?"	
				Event.emit_signal("special_event", "%s failed to train: %s"%[exemplarData.entityName, trainingPlanEntry.data['error']], 'training_problem')
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			# Make sure the training still exists in the specified location - it might be either the same location we are training, or the exemplar's organizer. If not, recycle the whole entry and mark it as failed, continue loop
			var trainingSourceOrganizerData = GameState.get_organizer_data(trainingPointer.get('src'))
			if !trainingSourceOrganizerData:
				trainingPlanEntry.data['error'] = "The source of the training no longer exists - was the location or equipment destroyed?"
				Event.emit_signal("special_event", "%s failed to train: %s"%[exemplarData.entityName, trainingPlanEntry.data['error']], 'training_problem')
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			var srcTrainingEntries = trainingSourceOrganizerData.get_entries_with_type('training')
			if !srcTrainingEntries: 
				srcTrainingEntries = []
			var trainingData
			for srcTrainingEntry in srcTrainingEntries:
				var trainOptions = srcTrainingEntry.data.get('train', [])
				for trainOption in trainOptions:
					if trainOption is Dictionary and trainOption.get('id') == trainingPointer.get('id',''):
						trainingData = trainOption
						break
			if !trainingData:
				trainingPlanEntry.data['error'] = "The equipment used in the training no longer exists - was it destroyed?"
				Event.emit_signal("special_event", "%s failed to train: %s"%[exemplarData.entityName, trainingPlanEntry.data['error']], 'training_problem')
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			# Hydrate trainingData
			var trainingDataObj:TrainingData = TrainingData.new()
			trainingDataObj.deserialize(trainingData)
			trainingData = trainingDataObj
			# Load any training modifiers from the location
			trainingData.load_location_modifications(trainingPointer.get('loc'))
			# Check whether the user's stats still allow them to perform the training - if not, recycle the whole entry and mark it as failed, continue loop
			var trainError = trainingData.exemplar_can_train(exemplarData)
			if trainError:
				trainingPlanEntry.data['error'] = trainError
				Event.emit_signal("special_event", "%s failed to train \"%s\": %s"%[exemplarData.entityName, trainingData.description, trainingPlanEntry.data['error']], 'training_problem')
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			# Perform the training
			trainingPlanEntry.data.erase('error')
			trainingData.train_exemplar(exemplarData)
			# Decrement the count by 1
			trainingPointer['count'] = trainingPointer.get('count', 1)-1
			# If the training is repeatable recycle the entry with a count of 1
			if trainingPointer.get('repeat', false):
				var recycled = trainingPlanEntry.duplicate(true)
				recycled['data']['count'] = 1
				entriesToRecycle.append(recycled)
			# If the count <= 0 delete the entry
			if trainingPointer['count'] <= 0:
				trainingOrganizerData.entries.remove(0)
			# break from the loop, as we've done our one training for the day
			break
		# handle recycled entries
		for recycle in entriesToRecycle:
			var recycleData = recycle.get('data')
			var finalEntryData = {}
			if trainingOrganizerData.entries.size() > 0:
				finalEntryData = trainingOrganizerData.entries[trainingOrganizerData.entries.size()-1].data
			if finalEntryData.get('loc') == recycleData.get('loc') and finalEntryData.get('src') == recycleData.get('src') and finalEntryData.get('id') == recycleData.get('id') and finalEntryData.get('repeat') == recycleData.get('repeat') and finalEntryData.get('count', 1) + recycleData.get('count', 1) <= 5:
				# Identical in every way, and the counts are small enough to merge, so do that
				finalEntryData['count'] = finalEntryData['count'] + recycle.data['count']
				if recycle.data.get('error'):
					finalEntryData['error'] = recycle.data.get('error')
			else:
				# not identical, just append the entry
				trainingOrganizerData.entries.append(recycle)
			# update counters for first/last entries
		if trainingOrganizerData.entries.size() > 0:
			update_training_entry_counter_text(trainingOrganizerData.entries[trainingOrganizerData.entries.size()-1])
			update_training_entry_counter_text(trainingOrganizerData.entries[0])
		exemplarData.on_training_complete()
	Event.emit_signal('training_queues_updated')

func update_training_entry_counter_text(entry):
	var n = entry.get('name','x0')
	n = n.substr(0, n.length() - 2) + 'x' + str(entry.get('data', {}).get('count', 1))
	entry['name'] = n

func process_consumers():
	var consumers
	for organizerName in GameState._organizers:
		if organizerName == null: continue
		var organizerData:OrganizerData = GameState.get_organizer_data(organizerName)
		consumers = organizerData.collect_resource_consumers()
		for consumer in consumers:
			consume_resources(consumer)

func consume_resources(consumer):
	consumer['consumed'] = {}
	var wasActive = consumer.get('active', true)
	consumer.erase('active')
	var resourcesNeeded = consumer.get('consume', {})
	for k in resourcesNeeded:
		var amtNeeded = resourcesNeeded.get(k, 0)
		if amtNeeded <= 0: continue
		var amtAvailable = GameState.resources.get(k, 0)
		var amtConsumed = min(amtNeeded, amtAvailable)
		GameState.resources[k] = amtAvailable - amtConsumed
		if amtConsumed < amtNeeded:
			consumer['active'] = false
		consumer['consumed'][k] = amtConsumed
	needToRefresh = needToRefresh or (wasActive != consumer.get('active', true))
	
func process_projects():
	collect_projects()
	for organizerDataEntry in processingProjects:
		var resourceConsumer = get_as_resource_consumer(organizerDataEntry.get('data'))
		if !resourceConsumer:
			printerr('Expected data to be a resource consumer, but was not: ', organizerDataEntry)
			return
		resourceConsumer.consume_resources()
		needToRefresh = true
		
		#organizerDataEntry['data'] = resourceConsumer.serialize()
		#print('dataEntry: ', organizerDataEntry['data'])
	GameState.reset_transient_resources()
	if needToRefresh: # at least one project may have been updated
		GameState.refresh_organizers()
		needToRefresh = false

func collect_projects():
	processingProjects = []
	for organizerName in projectOrganizers:
		process_organizer(organizerName)

func process_organizer(organizerName):
	var organizerData:OrganizerData = GameState.get_organizer_data(organizerName)
	processingProjects += organizerData.collect_projects()
	
func get_as_resource_consumer(data):
	if data is DecreeData: return data
#	if data.get('cmd') == 'decree':
#		var result = DecreeData.new()
#		result.deserialize(data)
#		return result
	return null
