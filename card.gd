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
@export var power: int
@export var move_points: int
@export var area_type: AreaType = AreaType.RECTANGLE
@export var area_length: int = 1
# Area width should in general be odd.
@export var area_width: int = 1

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

func apply_self(character: Character):
	assert(target_mode == TargetMode.SELF or target_mode == TargetMode.SELF_ALLY)
	if move_points > 0:
		character.move_points += move_points
	if block > 0:
		character.block += block
	if power > 0:
		character.power += power
	character.refresh()
	
func apply_ally(character: Character, ally: Character):
	assert(target_mode == TargetMode.SELF_ALLY or target_mode == TargetMode.ALLY)
	
func effective_damage(character: Character):
	var new_damage = damage
	if character.power > 0:
		new_damage *= 1.5
	return int(new_damage)

func apply_enemy(character: Character, enemy: Enemy):
	assert(target_mode == TargetMode.ENEMY or target_mode == TargetMode.AREA)
	enemy.hit_points -= effective_damage(character)
	enemy.refresh()
	if enemy.hit_points <= 0:
		return true
	return false
