extends Relic

class_name CombatLowHealthDamage

@export var health_fraction: float
@export var extra_damage: int

func apply_damage_change(damage: int, character: Character):
	if (character.hit_points / character.total_hit_points) <= health_fraction:
		return damage + extra_damage
	return damage
