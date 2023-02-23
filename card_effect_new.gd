extends Resource

class_name CardEffectNew

enum ValueType {
	NO_VALUE,
	ABSOLUTE,
	REFERENCE,
	SNAPSHOT_REFERENCE,
}

enum EffectType {
	NO_EFFECT,
	FIELD,
	EFFECT,
}

enum Field {
	NO_FIELD,
	HIT_POINTS,
	TOTAL_HIT_POINTS,
	MOVE_POINTS,
	TOTAL_MOVE_POINTS,
	ACTION_POINTS,
	TOTAL_ACTION_POINTS,
	BLOCK,
	POWER,
	WEAKNESS,
}

var field_name = {
	Field.HIT_POINTS: "HP",
	Field.TOTAL_HIT_POINTS: "total HP",
	Field.MOVE_POINTS: "MP",
	Field.TOTAL_MOVE_POINTS: "total MP",
	Field.ACTION_POINTS: "AP",
	Field.TOTAL_ACTION_POINTS: "total AP",
	Field.BLOCK: "[url]block[/url]",
	Field.POWER: "[url]power[/url]",
	Field.WEAKNESS: "weakness",
}

enum ReadOnlyField {
	NO_FIELD,
	HAND_CARDS,
}

var read_only_field_name = {
	ReadOnlyField.HAND_CARDS: "number of cards in your hand",
}

enum ValueFieldType {
	NO_FIELD_TYPE,
	REGULAR,
	READ_ONLY,
}

enum Effect {
	NO_EFFECT,
	DISCARD_HAND,
	DRAW_CARDS,
	DRAW_ATTACKS,
	COLLECTION_UPGRADE
}

@export var value_type: ValueType
@export var absolute_value: int
@export var reference_fraction: float
@export var value_field_type: ValueFieldType
@export var regular_field: Field
@export var read_only_field: ReadOnlyField
@export var effect_type: EffectType
@export var target_field: Field
@export var effect: Effect

func _get_value(character: Character):
	if value_type == ValueType.ABSOLUTE:
		return absolute_value
	if value_type == ValueType.REFERENCE:
		var original_value = _get_reference_value(character)
		return int(original_value * reference_fraction)
	elif value_type == ValueType.SNAPSHOT_REFERENCE:
		var original_value = _get_snapshot_value(character)
		return int(original_value * reference_fraction)

func _get_reference_value(character: Character):
	if value_field_type == ValueFieldType.REGULAR:
		pass
	elif value_field_type == ValueFieldType.READ_ONLY:
		match read_only_field:
			ReadOnlyField.HAND_CARDS: return character.num_hand_cards()

func _get_snapshot_value(character: Character):
	if value_field_type == ValueFieldType.REGULAR:
		pass
	elif value_field_type == ValueFieldType.READ_ONLY:
		match read_only_field:
			ReadOnlyField.HAND_CARDS: return character.snapshot.num_hand_cards

func apply_to_character(character: Character):
	var value = _get_value(character)
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND:
				character.discard()
			Effect.DRAW_CARDS:
				character.draw_cards(value)
	elif effect_type == EffectType.FIELD:
		match regular_field:
			Field.MOVE_POINTS: character.move_points += value

func _get_regular_field_name(field: Field):
	return field_name[field]

func _get_read_only_field_name(field: ReadOnlyField):
	return read_only_field_name[field]

func _get_field_name():
	if value_field_type == ValueFieldType.REGULAR:
		return _get_regular_field_name(regular_field)
	elif value_field_type == ValueFieldType.READ_ONLY:
		return _get_read_only_field_name(read_only_field)

func _get_value_string():
	if value_type == ValueType.ABSOLUTE:
		return "%d" % absolute_value
	if value_type == ValueType.REFERENCE:
		return "%s %s" % ["current", _get_field_name()]
	elif value_type == ValueType.SNAPSHOT_REFERENCE:
		return "%s %s" % ["original", _get_field_name()]

func get_description() -> String:
	var effect_text = ""
	var value_text = _get_value_string()
	if effect_type == EffectType.EFFECT:
		match effect:
			Effect.DISCARD_HAND: effect_text = "discard your hand"
			Effect.DRAW_CARDS: effect_text = "draw (%s) cards" % _get_value_string()
	elif effect_type == EffectType.FIELD:
		var prefix_text = "add"
		if value_type == ValueType.ABSOLUTE and absolute_value < 0:
			prefix_text = "remove"
		effect_text = "%s (%s) %s" % [prefix_text, value_text, _get_regular_field_name(target_field)]
	return effect_text
