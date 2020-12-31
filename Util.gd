extends Node
class_name Util

const MAX_INT = 9223372036854775807

const DATATYPE_DICT = 0
const DATATYPE_DECREE = 1
const DATATYPE_EXEMPLAR = 2

const noDrag = 1<<0
const isToggle = 1<<1
const noDelete = 1<<2
const noEdit = 1<<3
const isProject = 1<<4
const isOpen = 1<<5
const isUnread = 1<<6

const flagNameMap = {
	'noDrag': noDrag,
	'isToggle': isToggle,
	'toggle': isToggle,
	'noDelete': noDelete,
	'noDel': noDelete,
	'noEdit': noEdit,
	'isProject': isProject,
	'project': isProject,
	'isOpen': isOpen,
	'open': isOpen,
	'isUnread': isUnread,
	'unread': isUnread
}

static func sort_priority_array_desc(a, b):
	# sort in descending order, where a & b are arrays with the first element being the priority
	# ex: [ [3, "Three"], [4, "Four"], [1, "One"], [2, "Two"] ].sort_custom(Util, "sort_priority_array_desc")
	# returns: [[4, "Four"], [3, "Three"], [2, "Two"], [1, "One"] ]
	return a[0] > b[0]
	
static func build_entry_flags(flagNameArr:Array):
	if !flagNameArr is Array: 
		printerr('Unexpected flagNameArr, expected an array: ', flagNameArr)
		return 0
	var result = 0
	for flagName in flagNameArr:
		result = result | flagNameMap.get(flagName, 0)
	return result
			

static func clear_children(node:Node):
	for n in node.get_children():
		n.queue_free()
		node.remove_child(n)

static func load_text_file(filename:String)->String:
	if !filename.begins_with('res://') and !filename.begins_with('user://'): return filename
	var file = File.new()
	var err = file.open(filename, File.READ)
	if err: 
		printerr('Error opening ', filename, ': ', err)
		return ''
	var content = file.get_as_text()
	file.close()
	return content

static func load_json_file(filename:String):
	var content = load_text_file(filename)
	if content: return parse_json(content)
	else:
		printerr("Can't parse empty content in ", filename)
		return null

# Given a mean, standard deviation and a percentile from 0 to 1, give the value of a bell-shaped distribution at that percentile 
static func bell_curve(mean, stdev, percentile):
	# See: view-source:https://www.tribology-abc.com/calculators/t1_2b.htm
	var m = mean
	var s = stdev
	var p = percentile
	var prob1 = (s<=0)
	var prob2 = (p<=0)||(p>=1)
	if prob1:
		printerr('stdev must be >= 0')
		return mean
	if p<0: p = 0
	if p>1: p = 1
	
	var a1=2.30753; 
	var a2=.27061;
	var a3=.99229;
	var a4=.04481;
	var q0=.5-abs(p-.5);
	var w=sqrt(-2*log(q0));
	var w1=a1+a2*w;
	var w2=1+w*(a3+w*a4);
	var z=w-w1/w2;
	if p<0.5: z = -z
	var x=s*z+m;
	return round(100*x)/100

static func rand_choice(arr):
	if !arr or !arr.size(): return null
	return arr[randi()%arr.size()]

const statsMetadata = {
	"str": {"name":"Strength", "desc":"Strength, endurance"},
	"agi": {"name":"Agility", "desc":"Speed, dexterity, agility"},
	"int": {"name":"Mental", "desc":"Mental aptitude, learned skills"},
	"will": {"name":"Will", "desc":"Force of will, spiritual strength"},
	"bone": {"name":"Skeletal strength", "desc":"Overall skeletal density"},
	"muscle": {"name":"Muscle strength", "desc":"How much bodily force you bring to bear"},
	"endurance": {"name":"Muscle endurance", "desc":"How much bodily punishment you can endure"},
	"b_recover": {"name":"Body recovery", "desc":"How quickly you recover from bodily insult"},
	"speed": {"name":"Speed", "desc":"Quickness when moving"},
	"dexterity": {"name":"Dexterity", "desc":"Precision when moving"},
	"ability": {"name":"Ability", "desc":"Innate mental faculties"},
	"m_sharpness": {"name":"Mental sharpness", "desc":"Ability to concentrate on mental tasks"},
	"skill": {"name":"Skill", "desc":"Acquired intellectual skills"},
	"m_recover": {"name":"Mental recovery", "desc":"Ability to recover from mental exertion or insult"},
	"mind": {"name":"Mental control", "desc":"Self-control of ones own thoughts"},
	"body": {"name":"Body control", "desc":"Self-control of ones own body"},
	"soul": {"name":"Spirit control", "desc":"Self-control of ones own spirit"},
	"armBoneStr": {"name":"Arm bone density", "desc":"Resist blunt injury or shocks to your arms"},
	"legBoneStr": {"name":"Leg bone density", "desc":"Resist blunt injury or shocks to your legs"},
	"skullBoneStr": {"name":"Skull density", "desc":"Resist blunt injury or shocks to your skull"},
	"coreBoneStr": {"name":"Core bone density", "desc":"Resist blunt injury or shocks to your core"},
	"armStr": {"name":"Arm muscle strength", "desc":"Generate physical force from your arms - swing weapons, punch, block"},
	"legStr": {"name":"Leg muscle strength", "desc":"Generate physical force from your legs - run, jump, kick, dodge"},
	"coreStr": {"name":"Core muscle strength", "desc":"Generate physical force from your core - carry heavy weights, resist grappling or pushing"},
	"gripStr": {"name":"Grip strength", "desc":"Generate physical force from your hands - resist disarming, climb, grapple, crush"},
	"armEnd": {"name":"Arm muscle endurance", "desc":"Resist fatigue from using your arms"},
	"legEnd": {"name":"Leg muscle endurance", "desc":"Resist fatigue from using your legs"},
	"gripEnd": {"name":"Grip endurance", "desc":"Resist fatigue from using your hands"},
	"coreEnd": {"name":"Core endurance", "desc":"Resist fatigue from using your core"},
	"fatigue": {"name":"Stamina", "desc":"Resist fatigue through superior training, preventing weakness, loss of balance, loss of focus"},
	"fatigueRecover": {"name":"Fatigue recovery", "desc":"Speed of recovery from exertion and fatigue"},
	"woundRecover": {"name":"Wound recovery", "desc":"Speed of recovery from physical injury"},
	"moveSpd": {"name":"Movement speed", "desc":"Speed when covering ground on your feet"},
	"attackSpd": {"name":"Attack speed", "desc":"Speed when attacking with hands or weapons"},
	"reactSpd": {"name":"React speed", "desc":"Speed when reacting to enemy actions"},
	"jumpAgi": {"name":"Jump skill", "desc":"Height and distance covered when jumping"},
	"attackAgi": {"name":"Attack skill", "desc":"Ability to cause damage with hands or weapons"},
	"defendAgi": {"name":"Defend skill", "desc":"Ability to prevent damage with hands or weapons"},
	"perceive": {"name":"Perception", "desc":"Ability to detect small details, to read the stance of enemies to predict upcoming movements"},
	"insight": {"name":"Insight", "desc":"Ability to uncover new principles and techniques through meditation"},
	"synthesis": {"name":"Synthesis", "desc":"Ability to combine principles and techniques to uncover more advanced insights"},
	"thinkSpeed": {"name":"Mental agility", "desc":"Speed of thought and mental reaction"},
	"focus": {"name":"Mental focus", "desc":"Amount of mental exertion you can bring to bear"},
	"multitask": {"name":"Multitasking", "desc":"Skill in juggling multiple mental tasks"},
	"musicInt": {"name":"Musical skill", "desc":"Skill with musical instruments"},
	"mathInt": {"name":"Math skill", "desc":"Skill in describing the world through formal math and logic"},
	"spatialInt": {"name":"Spatial awareness", "desc":"Ability to see the paths of projectiles or attacks, to know where your opponent will be as they move"},
	"languageInt": {"name":"Language skill", "desc":"Ability to persuade or insult with words"},
	"emotionalInt": {"name":"Emotional awareness", "desc":"Ability to understand the motivations of others, or yourself"},
	"focusRecovery": {"name":"Focus recovery", "desc":"Speed of recovery from mental exertion"},
	"emptyMind": {"name":"Clear thought", "desc":"Ability to empty your mind of extraneous thought"},
	"resistManipulation": {"name":"Resist manipulation", "desc":"Resist mental manipulation techniques"},
	"resistConfusion": {"name":"Resist confusion", "desc":"Resist confusion"},
	"resistFatigue": {"name":"Resist fatigue", "desc":"Resist fatigue through sheer willpower, preventing weakness, loss of balance, loss of focus"},
	"resistDisorient": {"name":"Resist disorentation", "desc":"Resist disorientation and dizziness"},
	"spiritFatigue": {"name":"Spiritual endurance", "desc":"Resist spiritual fatigue, preventing wasted spiritual energy and sloppy techniques"},
	"spiritRecover": {"name":"Spiritual recovery", "desc":"Speed of recovery from spiritual strain"},
	"resistDomination": {"name":"Resist domination", "desc":"Resist domination techniques"},
	"determination": {"name":"Determination", "desc":"Improve training outcomes by pushing harder, succeed by force of will even in impossible situations"},
}

static func get_stat_friendly_name(statName):
	return statsMetadata.get(statName, {}).get("name", statName)

static func get_stat_description(statName):
	return statsMetadata.get(statName, {}).get("desc", '')

static func merge_maps(destMapToModify, sourceMap):
	for k in sourceMap:
		var orig = destMapToModify.get(k, 0)
		destMapToModify[k] = orig + sourceMap[k]
