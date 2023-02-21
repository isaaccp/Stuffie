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
	FRONT_AND_SIDES,  # Covers 3 tiles in front and both sides.
}

@export var card_name: String
@export var basic = false
@export var upgrade_level = 0
@export var base_card: Card
@export var cost: int
@export var texture: Texture2D
@export var target_mode: TargetMode
@export var target_distance: int
@export var damage: int
# Use on_play_self_effect when creating a card that has
# extra side effect on self besides target.
@export var on_play_self_effect: CardEffect
@export var on_play_effect: CardEffect
@export var on_kill_effect: CardEffect
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
	elif area_type == AreaType.FRONT_AND_SIDES:
		tiles = [
			Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(-1, -1), Vector2i(-1, 1)
		]

	var new_effect_area = []
	var angle = Vector2.RIGHT.angle_to(direction)
	for pos in tiles:
		var rotated_pos = Vector2(pos).rotated(angle)
		rotated_pos.x = round(rotated_pos.x)
		rotated_pos.y = round(rotated_pos.y)
		new_effect_area.append(Vector2i(rotated_pos))

	return new_effect_area

func apply_effect(character: Character, effect: CardEffect):
	if not effect:
		return
	effect.apply_to_character(character)

func apply_effect_enemy(enemy: Enemy, effect: CardEffect):
	if not effect:
		return
	effect.apply_to_enemy(enemy)

func apply_self(character: Character):
	assert(target_mode == TargetMode.SELF or target_mode == TargetMode.SELF_ALLY)
	apply_effect(character, on_play_effect)
	character.refresh()

func apply_ally(character: Character, ally: Character):
	assert(target_mode == TargetMode.SELF_ALLY or target_mode == TargetMode.ALLY)
	apply_effect(ally, on_play_effect)
	apply_effect(character, on_play_self_effect)

func effective_damage(character: Character):
	# Cards with natural 0 damage are not intended to be attacks.
	if damage == 0:
		return 0
	var new_damage = damage
	new_damage = character.apply_relic_damage_change(new_damage)
	if character.power > 0:
		new_damage *= 1.5
	return int(new_damage)

func apply_enemy(character: Character, enemy: Enemy):
	assert(target_mode == TargetMode.ENEMY or target_mode == TargetMode.AREA)
	enemy.hit_points -= effective_damage(character)
	apply_effect_enemy(enemy, on_play_effect)
	apply_effect(character, on_play_self_effect)
	enemy.refresh()
	if enemy.hit_points <= 0:
		apply_effect(character, on_kill_effect)
		return true
	return false

func is_attack():
	return damage != 0
