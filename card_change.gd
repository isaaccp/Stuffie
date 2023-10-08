@tool
extends Resource

class_name CardChange

@export var cost_change: int
@export var exhaust: bool

func get_description():
	var effects_text: PackedStringArray = []
	if cost_change < 0:
		effects_text.push_back("reduce cost by %d💢" % -cost_change)
	elif cost_change > 0:
		effects_text.push_back("increase cost by %d💢" % cost_change)
	if exhaust:
		effects_text.push_back("add [url=exhaust]Exhaust[/url]")
	return ', '.join(effects_text)
