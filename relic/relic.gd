extends Resource

class_name Relic

@export var name: String
@export var tooltip: String

func apply_end_turn(character: Character):
	pass

func apply_end_stage(character: Character):
	pass

func apply_damage_change(damage: int, character: Character):
	return damage