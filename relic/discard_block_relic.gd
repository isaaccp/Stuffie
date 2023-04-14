extends Relic

class_name DiscardBlockRelic

@export var block_multiplier: int

func _tooltip():
	return "For each card discarded, gain %d block" % block_multiplier

func _on_stats_added(character: Character, field: Stats.Field, value: int):
	if field == Stats.Field.DISCARDED_CARDS:
		character.add_status(StatusDef.Status.BLOCK, block_multiplier * value)
