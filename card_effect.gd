extends Resource

class_name CardEffect

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
	var stats = Stats.new()
	var value = 0
	# Some effects don't need a value, so allow that.
	if effect_value:
		value = effect_value.get_value(character)
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND:
				var cards_discarded = character.discard()
				stats.add(character.character_type, Stats.Field.DISCARDED_CARDS, cards_discarded)
			Effect.DRAW_CARDS:
				character.draw_cards(value)
				stats.add(character.character_type, Stats.Field.EXTRA_CARDS_DRAWN, value)
			Effect.DRAW_CARDS:
				character.draw_attacks(value)
				stats.add(character.character_type, Stats.Field.EXTRA_CARDS_DRAWN, value)
			Effect.COLLECTION_UPGRADE:
				var tree = character.get_tree().current_scene
				var upgrade = upgrade_scene.instantiate() as CardUpgrade
				upgrade.initialize([character])
				tree.add_child(upgrade)
				await upgrade.done
				upgrade.queue_free()
				# TODO: Check if we actually upgraded.
				stats.add(character.character_type, Stats.Field.CARDS_UPGRADED, 1)
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS: character.move_points += value
			CardEffectValue.Field.ACTION_POINTS: character.action_points += value
			CardEffectValue.Field.HIT_POINTS:
				var hp_healed = character.heal(value)
				stats.add(character.character_type, Stats.Field.HP_HEALED, hp_healed)
			CardEffectValue.Field.TOTAL_HIT_POINTS:
					character.total_hit_points += value
					character.heal(value)
			CardEffectValue.Field.POWER:
				character.power += value
				stats.add(character.character_type, Stats.Field.POWER_ACQUIRED, value)
			CardEffectValue.Field.GOLD:
				character.shared_bag.add_gold(value)
				stats.add(character.character_type, Stats.Field.GOLD_EARNED, value)
			CardEffectValue.Field.BLOCK:
				character.block += value
				stats.add(character.character_type, Stats.Field.BLOCK_ACQUIRED, value)
	return stats

func apply_to_enemy(character: Character, enemy: Enemy):
	var stats = Stats.new()
	var value = 0
	if effect_value:
		value = effect_value.get_value(character)
	if effect_type == EffectType.EFFECT:
		pass
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS:
				enemy.move_points += value
				stats.add(character.character_type, Stats.Field.ENEMY_MOVE_REMOVED, value)
			CardEffectValue.Field.WEAKNESS:
				enemy.weakness += value
				stats.add(character.character_type, Stats.Field.WEAKNESS_APPLIED, value)
	return stats

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

static func join_effects_text(effects: Array[CardEffect]) -> String:
	var effect_texts: PackedStringArray = []
	for effect in effects:
		effect_texts.push_back(effect.get_description())
	return ', '.join(effect_texts)

static func apply_effects_to_character(character: Character, effects: Array[CardEffect]):
	for effect in effects:
		effect.apply_to_character(character)
