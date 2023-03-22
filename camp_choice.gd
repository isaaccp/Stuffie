extends Resource

class_name CampChoice

@export var title: String
@export var effects: Array[CardEffect]

func get_description():
	return "%s: %s" % [title, UnitCard.join_effects_text(null, effects)]
