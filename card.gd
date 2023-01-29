extends Resource

class_name Card

enum CardType {
	Attack,
}

@export var card_name: String
@export var description: String
@export var cost: int
@export var damage: int
@export var texture: Texture2D

func get_description_text() -> String:
	var format_vars = {
		"damage": damage
	}
	return description.format(format_vars)
	
func get_cost_text() -> String:
	return "%d" % cost
