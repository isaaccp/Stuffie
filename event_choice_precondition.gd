extends Resource

class_name EventChoicePrecondition

enum Type {
	GOLD,
	CHARACTER_TYPE,
}

@export var type: Type
# Whether to display the precondition as part of the choice.
@export var display = true
@export var gold: int
@export var character_types: Array[Enum.CharacterId]

func get_description():
	if not display:
		return ""
	if type == Type.GOLD:
		return "gold >= %d" % gold
