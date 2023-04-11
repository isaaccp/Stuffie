extends Resource

class_name Card

enum AreaType {
	RECTANGLE,
	FRONT_AND_SIDES,  # Covers 3 tiles in front and both sides.
	CONE,             # Starts in front of player at given width, and expands outwards for length, expanding by cone step.
	DIAMOND,          # Starts in position and expands outwards based on area_length. 1 is a "cross".
}

@export var card_name: String
@export var upgrade_name: String
@export var basic = false
@export var upgrade_level = 0
@export var base_card: Card
@export var cost: int
# If false, card can't be played.
@export var playable = true
@export var texture: Texture2D
@export var target_mode: Enum.TargetMode
# Should be "on_play_animation".
@export var target_animation: Enum.TargetAnimationType
@export var on_damage_animation: Enum.TargetAnimationType
@export var target_distance: int
@export var damage_value: CardEffectValue
# Use on_play_self_effects when creating a card that has
# extra side effect on self besides target. They are played before
# on_play_effects are played.
@export var on_play_self_effects: Array[CardEffect]
@export var on_play_effects: Array[CardEffect]
# Effects applied to target on attacks if attack causes damage (i.e.,
# it wasn't fully blocked or dodged).
@export var on_damage_effects: Array[CardEffect]
# Effects to be applied to self after rest of effects.
@export var on_play_after_effects: Array[CardEffect]
# Effects to be applied if this attack kills an enemy.
@export var on_kill_effects: Array[CardEffect]
# Those effects take place next turn if unit is still alive.
@export var on_next_turn_effects: Array[CardEffect]
@export var area_type: AreaType = AreaType.RECTANGLE
@export var area_length: int = 1
# Area width should in general be odd.
@export var area_width: int = 1
@export var cone_step: int = 1
@export var power_relic: Relic
@export var exhaust: bool

func should_exhaust():
	if exhaust:
		return true
	# Consider manually setting "exhaust" in power
	# so some of them could not "exhaust".
	if power_relic:
		return true
	return false

func is_attack():
	return damage_value != null

func apply_card_change(change: CardChange):
	cost += change.cost_change
	if cost < 0:
		cost = 0
	if change.exhaust:
		exhaust = true

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
	elif area_type == AreaType.CONE:
		var width_idx = (area_width-1)/2
		for i in range(area_length):
			for j in range(-width_idx, width_idx+1):
				tiles.push_back(Vector2i(i, j))
			width_idx += cone_step
	elif area_type == AreaType.DIAMOND:
		for i in range(-area_length, area_length+1):
			for j in range(-area_length, area_length+1):
				if abs(i) + abs(j) <= area_length:
					tiles.push_back(Vector2i(i, j))

	var new_effect_area = []
	var angle = Vector2.RIGHT.angle_to(direction)
	for pos in tiles:
		var rotated_pos = Vector2(pos).rotated(angle)
		rotated_pos.x = round(rotated_pos.x)
		rotated_pos.y = round(rotated_pos.y)
		new_effect_area.append(Vector2i(rotated_pos))

	return new_effect_area

func extra_tooltips() -> Dictionary:
	var tooltips = {}
	if power_relic:
		tooltips[power_relic.name.to_lower()] = power_relic.tooltip
	return tooltips

static func filter_condition(card_filter: CardFilter):
	var property_conditions = {
		CardFilter.Property.ANY: func(c: Card): return true,
		CardFilter.Property.ATTACK: func(c: Card): return c.is_attack(),
	}
	if card_filter:
		return property_conditions[card_filter.property]
	return (func(c: Card): return true)
