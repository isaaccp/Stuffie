extends Resource

class_name RelicList

@export var relics: Array[Relic]

@export var available_relics: Dictionary

func reset():
	# TODO: Filter out not unlocked relics.
	for relic in relics:
		available_relics[relic.name] = relic

func choose(number: int):
	var options = available_relics.values()
	options.shuffle()
	return options.slice(0, number, 1, true)

func mark_used(name: String):
	available_relics.erase(name)

func available(name: String):
	return available_relics.has(name)
