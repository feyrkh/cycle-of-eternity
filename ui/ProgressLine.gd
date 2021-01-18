extends Line2D

onready var emptySegment:Line2D = self
onready var progressLine:Line2D = $ProgressLine
export(String) var statName = "fatigue"
export(String) var maxStatName = "max_fatigue"
export(Color) var backgroundColor
var statEntity

var lastAmt = 0
var lastMax = 0

func _ready():
	progressLine.width = width
	progressLine.default_color = self.default_color
	self.default_color = backgroundColor
	progressLine.visible = true
	

func _process(_delta):
	if statEntity:
		var amt = float(statEntity.get_stat(statName))
		var maxAmt = statEntity.get_stat(maxStatName)
		if lastAmt != amt or lastMax != maxAmt:
			lastAmt = amt
			lastMax = maxAmt
			var pct = 0
			if maxAmt != 0: 
				pct = (amt/maxAmt)
			progressLine.points[0] = points[0]
			progressLine.points[1] = lerp(points[0], points[1], pct)

