extends Resource

class_name EventChoicePrecondition

enum Type {
	GOLD,
	CHARACTER_TYPE,
	CARD,
}

@export var type: Type
# Whether to display the precondition as part of the choice.
@export var display = true
@export var gold: int
@export var character_types: Array[Enum.CharacterId]
@export var card: Card

func get_description():
	if type == Type.GOLD:
		return "gold >= %d" % gold
	elif type == Type.CHARACTER_TYPE:
		var names: PackedStringArray = []
		for character_type in character_types:
			names.push_back(Enum.CharacterId.keys()[character_type].capitalize())
		return ", ".join(names)
	elif type == Type.CARD:
		return "card: %s" % card.card_name
