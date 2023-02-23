extends Resource

class_name CardEffectNew

enum EffectType {
	NO_EFFECT,
	FIELD,
	EFFECT,
}

enum Effect {
	NO_EFFECT,
	DISCARD_HAND,
	DRAW_CARDS,
	DRAW_ATTACKS,
	COLLECTION_UPGRADE
}

@export var effect_value: CardEffectValue
@export var effect_type: EffectType
@export var target_field: CardEffectValue.Field
@export var effect: Effect

func apply_to_character(character: Character):
	var value = 0
	# Some effects don't need a value, so allow that.
	if effect_value:
		value = effect_value.get_value(character)
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND:
				character.discard()
			Effect.DRAW_CARDS:
				character.draw_cards(value)
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS: character.move_points += value

func get_description() -> String:
	var effect_text = ""
	var value_text = ""
	if effect_value:
		value_text = effect_value.get_value_string()
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND: effect_text = "discard your hand"
			Effect.DRAW_CARDS: effect_text = "draw (%s) cards" % value_text
	elif effect_type == EffectType.FIELD:
		var prefix_text = "add"
		if effect_value.is_negative():
			prefix_text = "remove"
		effect_text = "%s (%s) %s" % [prefix_text, value_text, CardEffectValue.get_regular_field_name(target_field)]
	return effect_text
