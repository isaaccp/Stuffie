@tool
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
	STATUS,
}

enum Field {
	NO_FIELD,
	HIT_POINTS,
	TOTAL_HIT_POINTS,
	MOVE_POINTS,
	TOTAL_MOVE_POINTS,
	ACTION_POINTS,
	TOTAL_ACTION_POINTS,
	GOLD,
}

const field_name = {
	Field.HIT_POINTS: "HP",
	Field.TOTAL_HIT_POINTS: "total HP",
	Field.MOVE_POINTS: "[url]MP[/url]",
	Field.TOTAL_MOVE_POINTS: "total MP",
	Field.ACTION_POINTS: "AP",
	Field.TOTAL_ACTION_POINTS: "total AP",
	Field.GOLD: "G",
}

enum ReadOnlyField {
	NO_FIELD,
	SNAPSHOT_HAND_CARDS,
	CARDS_PLAYED_TURN,
	MP_USED_TURN,
}

const read_only_field_name = {
	ReadOnlyField.SNAPSHOT_HAND_CARDS: "the original number of cards in your hand",
	ReadOnlyField.CARDS_PLAYED_TURN: "the cards played this turn",
	ReadOnlyField.MP_USED_TURN: "the MP used this turn"
}

@export var value_type: ValueType
@export var absolute_value: int = 0
@export var reference_fraction: float = 1.0
@export var value_field_type: ValueFieldType
@export var regular_field: Field
@export var read_only_field: ReadOnlyField
@export var status: StatusDef.Status

static func get_regular_field_name(field: Field):
	return field_name[field]

static func get_read_only_field_name(field: ReadOnlyField):
	return read_only_field_name[field]

func get_field_name():
	if value_field_type == ValueFieldType.REGULAR:
		return CardEffectValue.get_regular_field_name(regular_field)
	elif value_field_type == ValueFieldType.READ_ONLY:
		return CardEffectValue.get_read_only_field_name(read_only_field)
	elif value_field_type == ValueFieldType.STATUS:
		return StatusMetadata.status_name(status)
