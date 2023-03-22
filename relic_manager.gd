extends Resource

class_name RelicManager

@export var relics: Array[Relic]
@export var temp_relics: Array[Relic]

func add_relic(relic: Relic):
	relics.push_back(relic.duplicate())

func add_temp_relic(relic: Relic):
	temp_relics.push_back(relic.duplicate())

func clear_temp_relics():
	temp_relics.clear()
