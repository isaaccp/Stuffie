extends Relic

class_name EndTurnAutoBlockRelic

@export var block_amount: int

func apply_end_turn(character: Character):
	if character.block == 0:
		character.add_block(block_amount)
