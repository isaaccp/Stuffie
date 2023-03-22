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
				description += "Original: %s\n" % metadata.original_card_change.get_description()
			if metadata.copied_card_change:
				description += "New: %s\n" % metadata.copied_card_change.get_description()
	return description
