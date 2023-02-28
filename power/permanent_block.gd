extends Relic

class_name PermanentBlock

func _on_start_turn(character: Character):
	character.block = character.snapshot.block
