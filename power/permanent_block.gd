extends Relic

class_name PermanentBlock

func _tooltip():
	return "Don't remove block at beginning of turn"

func _on_start_turn(character: Character):
	character.status_manager.set_status(StatusDef.Status.BLOCK, character.snapshot.status_manager.get_status(StatusDef.Status.BLOCK))
