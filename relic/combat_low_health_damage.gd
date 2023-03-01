extends Relic

class_name CombatLowHealthDamage

@export var health_fraction: float
@export var extra_damage: int

func apply_damage_change(character: Character, damage: int):
	if (float(character.hit_points) / float(character.total_hit_points)) <= health_fraction:
		return damage + extra_damage
	return damage
