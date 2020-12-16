extends Object
class_name Conversation

var characters={}
var buffer = []

func run():
	while buffer.size() > 0:
		var entry = buffer.pop_front()
		match entry[0]:
			'page': yield(run_page(entry[1]), 'completed')
			'text': yield(run_text(entry[1]), 'completed')
			'speaking': run_speaking(entry[1])
			'clear': run_clear()
			'pause': yield(run_pause(), 'completed')
			'cmd': run_cmd(entry[1], entry[2], entry[3])
			'yieldCmd': yield(run_yieldCmd(entry[1], entry[2], entry[3]), 'completed')
			'input': yield(run_input(entry[1], entry[2], entry[3]), 'completed')
			_: printerr('Unexpected conversation command: ', entry[0], ' in entry: ', entry)


func character(name, displayName, imgPath):
	characters[name] = {'displayName':displayName.format(GameState.settings), 'imgPath':imgPath.format(GameState.settings)}

func pause():
	buffer.append(['pause'])

func run_pause():
	if Event.textInterface._buffer.length() > 0:
		yield(Event.textInterface, 'buff_end')


func page(text:String):
	buffer.append(['page', text])
	yield(Event.textInterface, 'buff_end')

func run_page(text):
	if text != null:
		text = text.trim_prefix('\n')
		Event.textInterface.buff_text(text.format(GameState.settings))
	Event.textInterface.buff_break()
	yield(Event.textInterface, 'buff_end')
	
func text(text):
	buffer.append(['text', text])
	yield(Event.textInterface, 'buff_end')
	
func run_text(text):
	Event.textInterface.buff_text(text.format(GameState.settings))
	yield(Event.textInterface, 'buff_end')
	
func speaking(name=null):
	buffer.append(['speaking', name])

func run_speaking(name):
	if name && characters.has(name): Event.show_character('res://img/people/%s.png'%characters[name]['imgPath'])
	else: Event.hide_character()

func clear():
	buffer.append(['clear'])

func run_clear():
	Event.clear_text()

# Use like: yield(conv.run(self, 'whenConvComplete', ['arg1', 'arg2']), 'completed')
func cmd(obj, method, args=[], shouldYield=false):
	if shouldYield:
		buffer.append(['yieldCmd', obj, method, args])
	else:
		buffer.append(['cmd', obj, method, args])

func run_cmd(obj, method, args):
	if obj && obj.has_method(method): 
		#yield(Event.textInterface, 'buff_end')
		obj.callv(method, args)
	else: printerr('Tried to call invalid method "', method, '" on ', obj, ' from conversation')

func run_yieldCmd(obj, method, args):
	if obj && obj.has_method(method): 
		yield(obj.callv(method, args), 'completed')
	else: 
		printerr('Tried to call invalid method "', method, '" on ', obj, ' from conversation')
	

# Use like: yield(conv.input('What is your name?', self, 'onNameInput'))
func input(prompt, obj, method):
	buffer.append(['input', prompt, obj, method])

func run_input(prompt, obj, method):
	Event.textInterface.clear_text()
	Event.textInterface.buff_text(prompt+'\n\n> ')
	Event.textInterface.buff_input()
	var inputValue = yield(Event.textInterface,"input_enter")
	if obj && obj.has_method(method):
		obj.callv(method, [inputValue])
		
