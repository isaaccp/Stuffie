extends Relic

class_name EndTurnAutoBlockRelic

@export var block_amount: int

func _tooltip():
	return "If you end your turn with no block, gain %d block" % block_amount

func _on_end_turn(character: Character):
	if character.get_status(StatusDef.Status.BLOCK) == 0:
		character.add_status(StatusDef.Status.BLOCK, block_amount)
