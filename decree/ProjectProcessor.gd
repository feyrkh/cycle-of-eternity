extends Node

const DecreeData = preload("res://decree/DecreeData.gd")
const projectOrganizers = ['office']
var processingProjects = []
var needToRefresh = false

func complete_decree_project(decreeData:DecreeData):
	needToRefresh = true
	print('completed project: ', decreeData.projectName)

func process_projects():
	needToRefresh = false
	GameState.produce_resources()
	collect_projects()
	for organizerDataEntry in processingProjects:
		var resourceConsumer = get_as_resource_consumer(organizerDataEntry.get('data'))
		if !resourceConsumer:
			printerr('Expected data to be a resource consumer, but was not: ', organizerDataEntry)
			return
		resourceConsumer.consume_resources()

		#organizerDataEntry['data'] = resourceConsumer.serialize()
		
		print('dataEntry: ', organizerDataEntry['data'])
	GameState.reset_transient_resources()
	if needToRefresh: # some projects must have been completed!
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
