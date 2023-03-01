extends Relic

class_name EndTurnAutoBlockRelic

@export var block_amount: int

func _tooltip():
	return "If you end your turn with no block, gain %d block" % block_amount

func _on_end_turn(character: Character):
	if character.block == 0:
		character.add_block(block_amount)
