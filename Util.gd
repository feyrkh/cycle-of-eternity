extends Node
class_name Util

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
	"str": "Strength",
	"agi": "Agility",
	"int": "Mental",
	"will": "Will",
	"bone": "Skeletal strength",
	"muscle": "Muscle strength",
	"endurance": "Muscle endurance",
	"b_recover": "Body recovery",
	"speed": "Speed",
	"dexterity": "Dexterity",
	"ability":"Ability",
	"focus":"Focus",
	"skill":"Skill",
	"m_recover":"Mental recovery",
	"mind":"Mental control",
	"body":"Body control",
	"soul":"Spirit control",
	"armBoneStr":"Arm bone density",
	"legBoneStr":"Leg bone density",
	"skullBoneStr":"Skull density",
	"coreBoneStr":"Core bone density",
	"armStr":"Arm muscle strength",
	"legStr":"Leg muscle strength",
	"gripStr":"Grip strength",
	"armEnd":"Arm muscle endurance",
	"legEnd": "Leg muscle endurance",
	"gripEnd": "Grip endurance",
	"coreEnd": "Core endurance",
	"fatigue": "Exertion endurance",
	"fatigueRecover": "Fatigue recovery",
	"woundRecover": "Wound recovery",
	"moveSpd": "Movement speed",
	"attackSpd": "Attack speed",
	"reactSpd": "React speed",
	"jumpAgi": "Jump skill",
	"attackAgi": "Attack skill",
	"defendAgi": "Defend skill",
	"perceive": "Perception",
	"insight": "Insight",
	"synthesis": "Synthesis",
	"proprioception": "Proprioception",
	"thinkSpeed": "Mental agility",
	"multitask": "Multitasking",
	"musicInt": "Musical skill",
	"mathInt": "Math skill",
	"spatialInt": "Spatial awareness",
	"languageInt": "Language skill",
	"emotionalInt": "Emotional awareness",
	"focusRecovery": "Focus recovery",
	"emptyMind": "Clear thought",
	"resistManipulation": "Resist manipulation",
	"resistConfusion": "Resist confusion",
	"resistFatigue": "Resist fatigue",
	"resistDisorient": "Resist disorentation",
	"spiritFatigue": "Spiritual endurance",
	"spiritRecover": "Spiritual recovery",
	"resistDomination": "Resist domination",
}
static func get_stat_friendly_name(statName):
	return statsMetadata.get(statName, statName)
