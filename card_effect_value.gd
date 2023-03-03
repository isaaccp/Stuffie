extends Resource

class_name CardEffectValue

enum ValueType {
	NO_VALUE,
	ABSOLUTE,
	REFERENCE,
}

enum ValueFieldType {
	NO_FIELD_TYPE,
	REGULAR,
	READ_ONLY,
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
	GOLD,
	DODGE,
}

const field_name = {
	Field.HIT_POINTS: "HP",
	Field.TOTAL_HIT_POINTS: "total HP",
	Field.MOVE_POINTS: "[url]MP[/url]",
	Field.TOTAL_MOVE_POINTS: "total MP",
	Field.ACTION_POINTS: "AP",
	Field.TOTAL_ACTION_POINTS: "total AP",
	Field.BLOCK: "[url]block[/url]",
	Field.POWER: "[url]power[/url]",
	Field.WEAKNESS: "weakness",
	Field.GOLD: "🪙",
	Field.DODGE: "[url]dodge[/url]",
}

enum ReadOnlyField {
	NO_FIELD,
	SNAPSHOT_HAND_CARDS,
}

const read_only_field_name = {
	ReadOnlyField.SNAPSHOT_HAND_CARDS: "original number of cards in your hand",
}

@export var value_type: ValueType
@export var absolute_value: int = 0
@export var reference_fraction: float = 1.0
@export var value_field_type: ValueFieldType
@export var regular_field: Field
@export var read_only_field: ReadOnlyField

func get_value(character: Character):
	if value_type == ValueType.ABSOLUTE:
		return absolute_value
	if value_type == ValueType.REFERENCE:
		if character != null:
			var original_value = _get_reference_value(character)
			return int(original_value * reference_fraction)
		return 0

func _get_reference_value(character: Character):
	if value_field_type == ValueFieldType.REGULAR:
		return get_field(character, regular_field)
	elif value_field_type == ValueFieldType.READ_ONLY:
		return get_read_only_field(character, read_only_field)

func get_field(character: Character, field: Field):
	match field:
		Field.TOTAL_HIT_POINTS: return character.total_hit_points
		Field.BLOCK: return character.block
	assert(false)

func get_read_only_field(character: Character, field: ReadOnlyField):
	match field:
		ReadOnlyField.SNAPSHOT_HAND_CARDS: return character.snapshot.num_hand_cards
	assert(false)

static func get_regular_field_name(field: Field):
	return field_name[field]

static func get_read_only_field_name(field: ReadOnlyField):
	return read_only_field_name[field]

func get_field_name():
	if value_field_type == ValueFieldType.REGULAR:
		return CardEffectValue.get_regular_field_name(regular_field)
	elif value_field_type == ValueFieldType.READ_ONLY:
		return CardEffectValue.get_read_only_field_name(read_only_field)

func get_value_string(character: Character):
	if value_type == ValueType.ABSOLUTE:
		return "%d" % absolute_value
	if value_type == ValueType.REFERENCE:
		return "%d%% of %s (%d)" % [reference_fraction * 100, get_field_name(), get_value(character)]

func is_negative():
	if value_type == ValueType.ABSOLUTE and absolute_value < 0:
		return true
	return false
