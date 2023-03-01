extends Relic

class_name PermanentBlock

func _tooltip():
	return "Don't remove block at beginning of turn"

func _on_start_turn(character: Character):
	character.block = character.snapshot.block
