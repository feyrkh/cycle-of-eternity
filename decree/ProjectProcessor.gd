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
	ProjectProcessor.process_projects()

func reset():
	needToRefresh = false

func complete_decree_project(decreeData:DecreeData):
	needToRefresh = true
	print('completed project: ', decreeData.projectName)

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
