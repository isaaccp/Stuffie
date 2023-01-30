extends Resource

class_name Card

enum TargetMode {
	SELF,
	ENEMY,
	AREA,
}

@export var card_name: String
@export var description: String
@export var cost: int
@export var damage: int
@export var texture: Texture2D
@export var target_mode: TargetMode
@export var target_distance: int

func get_description_text() -> String:
	var format_vars = {
		"damage": damage,
		"distance": target_distance,
	}
	return description.format(format_vars)
	
func get_cost_text() -> String:
	return "%d" % cost
