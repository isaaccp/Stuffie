extends Resource

class_name Relic

@export var name: String

var tooltip:
	get:
		return _tooltip()

func _tooltip():
	assert(false)

func _on_start_stage(character: Character):
	pass

func _on_end_stage(character: Character):
	pass

func _on_attack(character: Character):
	pass

func _on_start_turn(character: Character):
	pass

func _on_end_turn(character: Character):
	pass

func _on_card_played(character: Character, card: Card):
	pass

func _on_stats_added(character: Character, field: Stats.Field, value: int):
	pass

func camp_choices():
	return []

func apply_damage_change(character: Character, damage: int):
	return damage
