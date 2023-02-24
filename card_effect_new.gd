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

var upgrade_scene = preload("res://card_upgrade.tscn")

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
			Effect.DRAW_CARDS:
				character.draw_attacks(value)
			Effect.COLLECTION_UPGRADE:
				var tree = character.get_tree().current_scene
				var upgrade = upgrade_scene.instantiate() as CardUpgrade
				upgrade.initialize([character])
				tree.add_child(upgrade)
				await upgrade.done
				upgrade.queue_free()
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS: character.move_points += value
			CardEffectValue.Field.ACTION_POINTS: character.action_points += value
			CardEffectValue.Field.HIT_POINTS: character.heal(value)
			CardEffectValue.Field.TOTAL_HIT_POINTS:
					character.total_hit_points += value
					character.heal(value)
			CardEffectValue.Field.POWER: character.power += value
			CardEffectValue.Field.GOLD: character.shared_bag.add_gold(value)
			CardEffectValue.Field.BLOCK: character.block += value

func apply_to_enemy(character: Character, enemy: Enemy):
	var value = 0
	if effect_value:
		value = effect_value.get_value(character)
	if effect_type == EffectType.EFFECT:
		pass
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS: enemy.move_points += value
			CardEffectValue.Field.WEAKNESS: enemy.weakness += value

func get_description() -> String:
	var effect_text = ""
	var value_text = ""
	if effect_value:
		value_text = effect_value.get_value_string()
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND: effect_text = "discard your hand"
			Effect.DRAW_CARDS: effect_text = "draw (%s) cards" % value_text
			Effect.DRAW_ATTACKS: effect_text = "draw (%s) attack cards" % value_text
			Effect.COLLECTION_UPGRADE: effect_text = "upgrade (%s) cards" % value_text
	elif effect_type == EffectType.FIELD:
		var prefix_text = "add"
		if effect_value.is_negative():
			prefix_text = "remove"
			# Remove leading -.
			value_text = value_text.substr(1)
		effect_text = "%s (%s) %s" % [prefix_text, value_text, CardEffectValue.get_regular_field_name(target_field)]
	return effect_text

static func join_effects_text(effects: Array[CardEffectNew]) -> String:
	var effect_texts: PackedStringArray = []
	for effect in effects:
		effect_texts.push_back(effect.get_description())
	return ', '.join(effect_texts)

static func apply_effects_to_character(character: Character, effects: Array[CardEffectNew]):
	for effect in effects:
		effect.apply_to_character(character)
