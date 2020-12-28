extends ColorRect

func _ready():
	color = Color.lightgreen

func set_progress(amt):
	var maxSize = get_parent().rect_size.x
	self.rect_min_size.x = maxSize * amt

func set_progressing(madeProgress):
	if madeProgress:
		color = Color.lightgreen
		color.a = 0.2
	else:
		color = Color.orange
		color.a = 0.2

func update_from_organizer_entry(time_pass_amt, entry):
	if !entry or !entry.data or entry.data is Dictionary: 
		printerr("Can't update progress bar for ", self.label)
		return
	if entry.data.has_method('get_percent_complete'):
		set_progress(entry.data.get_percent_complete())
	if entry.data.has_method('get_progress_made'):
		set_progressing(entry.data.get_progress_made())
