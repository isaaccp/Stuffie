extends Relic

class_name CombatFirstStageAttackDamageRelic

@export var extra_damage: int

var used = false

func _on_start_stage(character: Character):
	used = false

func _on_attack(character: Character):
	used = true

func apply_damage_change(damage: int, character: Character):
	if not used:
		return damage + extra_damage
	return damage
