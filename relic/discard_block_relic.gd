extends Relic

class_name DiscardBlockRelic

@export var block_multiplier: int

func _on_stats_added(character: Character, field: Stats.Field, value: int):
	if field == Stats.Field.DISCARDED_CARDS:
		character.add_block(block_multiplier * value)
