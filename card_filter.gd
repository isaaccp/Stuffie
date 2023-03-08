extends Resource

class_name CardFilter

enum Property {
	ANY,
	ATTACK,
}

var property_conditions = {
	Property.ANY: func(c: Card): return true,
	Property.ATTACK: func(c: Card): return c.is_attack(),
}

@export var property: Property

func get_description():
	match property:
		Property.ANY: return "cards"
		Property.ATTACK: return "attack cards"

func condition():
	assert(property in property_conditions)
	return property_conditions[property]