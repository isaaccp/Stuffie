extends Resource

class_name Card

enum TargetMode {
	# Targets self.
	SELF,
	# Targets ally.
	ALLY,
	# Targets self or ally.
	SELF_ALLY,
	# Needs to target an enemy.
	ENEMY,
	# Can target any location within range.
	AREA,
}

enum AreaType {
	RECTANGLE,
}

@export var card_name: String
@export var description: String
@export var cost: int
@export var texture: Texture2D
@export var target_mode: TargetMode
@export var target_distance: int
@export var damage: int
@export var block: int
@export var move_points: int
@export var area_type: AreaType = AreaType.RECTANGLE
@export var area_length: int = 1
# Area width should in general be odd.
@export var area_width: int = 1

func get_description_text() -> String:
	var format_vars = {
		"damage": damage,
		"distance": target_distance,
		"move_points": move_points,
		"block": block,
	}
	return description.format(format_vars)
	
func get_cost_text() -> String:
	return "%d" % cost

# Returns a list of tiles that will be affected
# by card, with (0, 0) being the tile chosen by
# human. We support basic area types through
# properties, but a particular card could override.
func effect_area(direction: Vector2):
	var tiles = []
	if area_type == AreaType.RECTANGLE:
		var width_idx = (area_width-1)/2
		for i in range(area_length):
			for j in range(-width_idx, width_idx+1):
				tiles.push_back(Vector2i(i, j))
	var new_effect_area = []
	var angle = Vector2.RIGHT.angle_to(direction)
	for pos in tiles:
		new_effect_area.append(Vector2i(Vector2(pos).rotated(angle)))
	return new_effect_area
