extends Relic

class_name AddDamageAttacksPlayed

@export var extra_damage: int

func _tooltip():
	return "Each attack card played deals %d more damage the next times it is played this combat" % extra_damage

func _on_card_played(character: Character, card: Card):
	if card.is_attack():
		if card.damage_value.value_type == CardEffectValue.ValueType.ABSOLUTE:
			card.damage_value.absolute_value += extra_damage
