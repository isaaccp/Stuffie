extends Resource

class_name CardFilter

enum Property {
	ANY,
	ATTACK,
}

@export var property: Property

func get_description():
	match property:
		Property.ANY: return "cards"
		Property.ATTACK: return "attack cards"
