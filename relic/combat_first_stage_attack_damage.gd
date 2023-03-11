extends Relic

class_name CombatFirstStageAttackDamageRelic

@export var extra_damage: int

@export var used = false

func _tooltip():
	return "First attack on each stage does %d extra damage" % extra_damage

func _on_start_stage(character: Character):
	used = false

func _on_attack(character: Character):
	used = true

func apply_damage_change(character: Character, damage: int):
	if not used:
		return damage + extra_damage
	return damage
