extends Node
class_name KiUtil

# Max possible element is 15 
const Earth = 0
const Wood = 1
const Fire = 2
const Water = 3
const Metal = 4
const Dark = 5
const Heaven = 6
const Hell = 7
const Dream = 8
const Enlightenment = 9
const MaxElementId = 9

const ObstructionLayer = 19

const ElementImages = [
	preload('res://img/earth_egg.png'),
	preload('res://img/wood_egg.png'),
	preload('res://img/fire_egg.png'),
	preload('res://img/water_egg.png'),
	preload('res://img/metal_egg.png'),
	preload('res://img/wind_egg.png'),
	preload('res://img/wind_egg.png'),
	preload('res://img/wind_egg.png'),
	preload('res://img/wind_egg.png'),
	preload('res://img/wind_egg.png'),
]

const ElementName = [
	'earth', # creates metal, insults wood, destroys water
	'wood', # creates fire, insults metal, destroys earth
	'fire', # creates earth, insults water, destroys metal
	'water',  # creates wood, insults earth, destroys fire
	'metal', # creates water, insults fire, destroys wood
	'dark', # creates enlightenment, insults dream, destroys heaven
	'heaven', # creates dream, insults dark, destroys hell
	'hell', # creates dark, insults heaven, destroys enlightenment
	'dream', # creates hell, insults enlightenment, destroys dark
	'enlightenment' # creates heaven, insults hell, destroys dream
]

const ElementCollisionMask = [
	1<<Wood | 1<<Fire | 1<<Water | 1<<Metal | 1<<ObstructionLayer,
	1<<Fire | 1<<Water | 1<<Metal | 1<< Earth | 1<<ObstructionLayer,
	1<<Wood | 1<<Water | 1<<Metal | 1<< Earth | 1<<ObstructionLayer,
	1<<Wood | 1<<Fire | 1<<Metal | 1<< Earth | 1<<ObstructionLayer,
	1<<Wood | 1<<Fire | 1<<Water | 1<< Earth | 1<<ObstructionLayer,
	1<<Heaven | 1<<Hell | 1<<Dream | 1<<Enlightenment | 1<<ObstructionLayer,
	1<<Dark | 1<<Hell | 1<<Dream | 1<<Enlightenment | 1<<ObstructionLayer,
	1<<Dark | 1<<Heaven | 1<<Dream | 1<<Enlightenment | 1<<ObstructionLayer,
	1<<Dark | 1<<Heaven | 1<<Hell | 1<<Enlightenment | 1<<ObstructionLayer,
	1<<Dark | 1<<Heaven | 1<<Hell | 1<<Dream | 1<<ObstructionLayer
]

const ElementColor = [
	Color.beige,
	Color.brown,
	Color.red,
	Color.blue,
	Color.silver,
	Color.black,
	Color.gold,
	Color.burlywood,
	Color.aliceblue,
	Color.white
] 

# max possible refinement levels is 255 (256 total refinement levels)
const RefinementName = [
	'chaotic',
	'turbid',
	'wild', 
	'disordered',
	'unbalanced',
	'controlled',
	'purified',
	'ennobled',
	'organized',
	'methodical',
	'systematic',
	'harmonized',
	'ascended',
	'celestial',
	'eternal'
]
