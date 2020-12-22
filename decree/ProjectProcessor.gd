extends Node

const projectOrganizers = ['office']
var processingProjects = []

func process_projects():
	GameState.reset_transient_resources()
	GameState.produce_resources()
	collect_projects()
	for projectEntryData in processingProjects:
		projectEntryData.consume_resources()

func collect_projects():
	processingProjects = []
	for organizerName in projectOrganizers:
		process_organizer(organizerName)

func process_organizer(organizerName):
	var organizerData:OrganizerData = GameState.get_organizer_data(organizerName)
	processingProjects += organizerData.collect_projects()
	
