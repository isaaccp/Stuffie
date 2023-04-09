extends Resource

class_name EventDef

enum TargetType {
	ALL_CHARACTERS,
	RANDOM_CHARACTER,
	CHOOSE_CHARACTER,
}

@export var title: String
@export_multiline var event_text: String
@export var target_type: TargetType
@export var choices: Array[EventChoice]
