extends Button

class_name RelicButton

var relic: Relic

func _init(relic: Relic, relic_cost: int):
	self.relic = relic
	text = "%s %d🪙" % [relic.name, relic_cost]
	tooltip_text = relic.tooltip
