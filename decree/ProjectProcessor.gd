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
		var exemplarId = exemplarEntry.id
		var trainingOrganizerData = ExemplarData.get_training_organizer(exemplarEntry)
		var entriesToRecycle = []
		while trainingOrganizerData.entries.size() > 0:
			var trainingPlanEntry = trainingOrganizerData.entries[0]
			var trainingPointer = trainingPlanEntry.data
			# example trainingPointer: {"loc":locationWhereWeAreTraining, "src":organizerContainingTraining, "id":trainingData.id, "count": count, "repeat":repeat}
			# Make sure the training location still exists - if not, recycle the whole entry and mark it as failed, continue loop
			var trainingLocationOrganizerData = GameState.get_organizer_data(trainingPointer.get('loc'))
			if !trainingLocationOrganizerData: 
				trainingPlanEntry.data['fail'] = "The training location no longer exists - was the location destroyed?"
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			# Make sure the training still exists in the specified location - it might be either the same location we are training, or the exemplar's organizer. If not, recycle the whole entry and mark it as failed, continue loop
			var trainingSourceOrganizerData = GameState.get_organizer_data(trainingPointer.get('src'))
			if !trainingSourceOrganizerData:
				trainingPlanEntry.data['fail'] = "The source of the training no longer exists - was the location or equipment destroyed?"
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			var srcTrainingEntries = trainingOrganizerData.get_entries_with_type('training')
			if !srcTrainingEntries: 
				srcTrainingEntries = []
			var trainingData
			for srcTrainingEntry in srcTrainingEntries:
				if srcTrainingEntry.data is TrainingData and srcTrainingEntry.data.id == trainingPointer.get('id',''):
					trainingData = srcTrainingEntry.data
					break
			if !trainingData:
				trainingPlanEntry.data['fail'] = "The equipment used in the training no longer exists - was it destroyed?"
				entriesToRecycle.append(trainingPlanEntry)
				trainingOrganizerData.entries.remove(0)
				continue
			# Load any training modifiers from the location
			trainingData.load_location_modifications(trainingPointer.get('loc'))
			# Check whether the user's stats still allow them to perform the training - if not, recycle the whole entry and mark it as failed, continue loop
			#if !trainingData.exemplar_can_train(exemplarData):
			#	pass
			# Perform the training
			# Decrement the count by 1
			# If the training is repeatable recycle the entry with a count of 1
			# If the count <= 0 delete the entry
			# break from the loop, as we've done our one training for the day
		# handle recycled entries

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
