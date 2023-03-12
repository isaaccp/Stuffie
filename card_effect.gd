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
	COLLECTION_UPGRADE,
	PICK_CARDS,
	PICK_ATTACKS,
	TELEPORT,
	DUPLICATE_CARD,
}

@export var effect_value: CardEffectValue
@export var effect_type: EffectType
@export var target_field: CardEffectValue.Field
@export var effect: Effect
# This allows us to add extra metadata for some effects without
# adding too many fields to the basic CardEffect.
@export var metadata: CardEffectMetadata

# All stats are updated inside the character methods. That way objects like relics that don't use
# CardEffect will still update stats easily.
func apply_to_character(character: Character):
	var value = 0
	# Some effects don't need a value, so allow that.
	if effect_value:
		value = effect_value.get_value(character)
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND:
				character.discard_hand()
			Effect.DRAW_CARDS:
				character.draw_cards(value)
			Effect.DRAW_ATTACKS:
				character.draw_attacks(value)
			Effect.PICK_CARDS:
				await character.pick_cards(value)
			Effect.PICK_ATTACKS:
				await character.pick_attacks(value)
			Effect.COLLECTION_UPGRADE:
				# TODO: This ignores value and just upgrades one as of now.
				await character.upgrade_cards(value)
			Effect.TELEPORT:
				# TODO: Assert this is not invoked outside of combat.
				await character.teleport(value)
			Effect.DUPLICATE_CARD:
				await character.duplicate_cards(value, metadata)
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS: character.move_points += value
			CardEffectValue.Field.ACTION_POINTS: character.action_points += value
			CardEffectValue.Field.HIT_POINTS:
				character.heal(value)
			CardEffectValue.Field.TOTAL_HIT_POINTS:
					character.total_hit_points += value
					character.heal(value)
			CardEffectValue.Field.BLOCK:
				character.add_block(value)
			CardEffectValue.Field.DODGE:
				character.add_dodge(value)
			CardEffectValue.Field.POWER:
				character.add_power(value)
			CardEffectValue.Field.GOLD:
				character.add_gold(value)

func apply_to_enemy(character: Character, enemy: Enemy):
	var value = 0
	if effect_value:
		value = effect_value.get_value(character)
	if effect_type == EffectType.EFFECT:
		pass
	elif effect_type == EffectType.FIELD:
		match target_field:
			CardEffectValue.Field.MOVE_POINTS:
				enemy.move_points += value
				if value < 0:
					StatsManager.add(character.character_type, Stats.Field.ENEMY_MP_REMOVED, value)
			CardEffectValue.Field.WEAKNESS:
				enemy.weakness += value
				StatsManager.add(character.character_type, Stats.Field.WEAKNESS_APPLIED, value)
			CardEffectValue.Field.PARALYSIS:
				enemy.paralysis += value
				StatsManager.add(character.character_type, Stats.Field.PARALYSIS_APPLIED, value)

func get_description(character: Character) -> String:
	var effect_text = ""
	var value_text = ""
	if effect_value:
		value_text = effect_value.get_value_string(character)
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND: effect_text = "discard your hand"
			Effect.DRAW_CARDS: effect_text = "draw %s cards" % value_text
			Effect.DRAW_ATTACKS: effect_text = "draw %s attack cards" % value_text
			Effect.PICK_CARDS: effect_text = "shuffle discard into deck and pick %s cards" % value_text
			Effect.PICK_ATTACKS: effect_text = "shuffle discard into deck and pick %s attack cards" % value_text
			Effect.COLLECTION_UPGRADE: effect_text = "upgrade %s cards" % value_text
			Effect.TELEPORT: effect_text = "teleport up to %s tiles" % value_text
			Effect.DUPLICATE_CARD: effect_text = "create %s copies of %s in your hand\n%s" % [value_text, metadata_card_filter(), metadata_extra_description()]
	elif effect_type == EffectType.FIELD:
		var prefix_text = "add"
		if effect_value.is_negative():
			prefix_text = "remove"
			# Remove leading -.
			value_text = value_text.substr(1)
		effect_text = "%s %s %s" % [prefix_text, value_text, CardEffectValue.get_regular_field_name(target_field)]
	return effect_text

func metadata_card_filter():
	var property: CardFilter.Property
	if metadata.card_filter:
		property = metadata.card_filter.property
	else:
		property = CardFilter.Property.ANY
	match effect:
		Effect.DUPLICATE_CARD:
			match property:
				CardFilter.Property.ANY:
					return "a card"
				CardFilter.Property.ATTACK:
					return "an attack card"
	assert(false)

func metadata_extra_description():
	var description = ""
	match effect:
		Effect.DUPLICATE_CARD:
			if metadata.original_card_change:
				description += "Original card: %s\n" % metadata.original_card_change.get_description()
			if metadata.copied_card_change:
				description += "New card(s): %s\n" % metadata.copied_card_change.get_description()
	return description

static func join_effects_text(character: Character, effects: Array[CardEffect]) -> String:
	var effect_texts: PackedStringArray = []
	for effect in effects:
		effect_texts.push_back(effect.get_description(character))
	return ', '.join(effect_texts)

static func apply_effects_to_character(character: Character, effects: Array[CardEffect]):
	for effect in effects:
		await effect.apply_to_character(character)
