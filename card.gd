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
@export var texture: Texture2D
@export var target_mode: Enum.TargetMode
@export var target_animation: Enum.TargetAnimationType
@export var target_distance: int
@export var damage_value: CardEffectValue
# Use on_play_self_effects when creating a card that has
# extra side effect on self besides target.
@export var on_play_self_effects: Array[CardEffect]
@export var on_play_effects: Array[CardEffect]
# Effects to be applied to self after rest of effects.
@export var on_play_after_effects: Array[CardEffect]
@export var on_kill_effects: Array[CardEffect]
@export var area_type: AreaType = AreaType.RECTANGLE
@export var area_length: int = 1
# Area width should in general be odd.
@export var area_width: int = 1
@export var cone_step: int = 1
@export var power_relic: Relic
@export var exhaust: bool

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

func apply_on_play_effects(character: Character):
	await CardEffect.apply_effects_to_character(character, on_play_effects)

func apply_self(character: Character):
	assert(target_mode == Enum.TargetMode.SELF or target_mode == Enum.TargetMode.SELF_ALLY)
	if power_relic:
		character.add_temp_relic(power_relic)
	await apply_on_play_effects(character)
	character.refresh()

func apply_self_effects(character: Character):
	CardEffect.apply_effects_to_character(character, on_play_self_effects)

func apply_after_effects(character: Character):
	await CardEffect.apply_effects_to_character(character, on_play_after_effects)

func apply_ally(character: Character, ally: Character):
	assert(target_mode == Enum.TargetMode.SELF_ALLY or target_mode == Enum.TargetMode.ALLY)
	apply_on_play_effects(character)
	apply_self_effects(character)

func should_exhaust():
	if exhaust:
		return true
	# Consider manually setting "exhaust" in power
	# so some of them could not "exhaust".
	if power_relic:
		return true
	return false

func regular_damage(character: Character):
	if damage_value:
		return damage_value.get_value(character)
	return 0

func effective_damage(character: Character):
	# Cards with natural 0 damage are not intended to be attacks.
	if regular_damage(character) == 0:
		return 0
	var new_damage = regular_damage(character)
	new_damage = character.apply_relic_damage_change(new_damage)
	if character.power > 0:
		new_damage *= 1.5
	return int(new_damage)

func get_damage_description(character: Character):
	if damage_value == null:
		return ""
	var regular_damage = regular_damage(character)
	var damage_text = "%d" % regular_damage
	if damage_value:
		damage_text = damage_value.get_value_string(character)
	var effective_damage = effective_damage(character)
	if regular_damage != effective_damage:
			damage_text = "%s ([color=red]%d[/color])" % [damage_text, effective_damage]
	return damage_text

func apply_enemy(character: Character, enemy: Enemy):
	assert(target_mode == Enum.TargetMode.ENEMY or target_mode == Enum.TargetMode.AREA)
	var attack_damage = effective_damage(character)
	StatsManager.add(character.character_type, Stats.Field.DAMAGE_DEALT, attack_damage)
	# TODO: Move this to a method inside Unit, shared with character, that emits
	# health_changed itself.
	enemy.hit_points -= attack_damage
	enemy.health_changed.emit()
	for effect in on_play_effects:
		effect.apply_to_enemy(character, enemy)
	enemy.refresh()
	if enemy.hit_points <= 0:
		CardEffect.apply_effects_to_character(character, on_kill_effects)
		return true
	return false

func is_attack():
	return damage_value != null

func get_target_text() -> String:
	var target_text = ""
	if target_mode == Enum.TargetMode.SELF:
		target_text = "Self"
	elif target_mode == Enum.TargetMode.SELF_ALLY:
		target_text = "Self or Ally"
	elif target_mode == Enum.TargetMode.ALLY:
		target_text = "Ally"
	elif target_mode == Enum.TargetMode.ENEMY:
		target_text = "Enemy"
	elif target_mode == Enum.TargetMode.AREA:
		var area_size = effect_area(Vector2.RIGHT).size()
		target_text = "Area (%d tiles)" % area_size
	return target_text

func on_play_effect_text(character: Character) -> String:
	return CardEffect.join_effects_text(character, on_play_effects)

func on_play_after_effect_text(character: Character) -> String:
	return CardEffect.join_effects_text(character, on_play_after_effects)

func apply_card_change(change: CardChange):
	cost += change.cost_change
	if cost < 0:
		cost = 0
	if change.exhaust:
		exhaust = true

func get_description(character: Character) -> String:
	var description = ""
	if should_exhaust():
		description = "[url=exhaust]Exhaust[/url]. "
	var target_text = get_target_text()
	var prefix_text = ""
	if target_text != "Self":
		prefix_text = "%s: " % target_text
	if target_mode in [Enum.TargetMode.SELF, Enum.TargetMode.SELF_ALLY or Enum.TargetMode.SELF_ALLY]:
		if power_relic:
			description += "Power: [url]%s[/url]\n" % power_relic.name
		var on_play_text = on_play_effect_text(character)
		if on_play_text:
			description += "%s%s\n" % [prefix_text, on_play_text]
	elif target_mode in [Enum.TargetMode.ENEMY, Enum.TargetMode.AREA]:
		var on_play_self_text = CardEffect.join_effects_text(character, on_play_self_effects)
		if on_play_self_text:
			description += "Before Play: %s\n" % on_play_self_text
		var attack_text = "Attack"
		var area_size = effect_area(Vector2.RIGHT).size()
		if area_size > 1:
			attack_text += (" enemies in area (%s tiles)" % area_size)
		var damage_text = get_damage_description(character)
		if damage_text:
			description += "%s for %s dmg\n" % [attack_text, damage_text]
		var on_play_text = on_play_effect_text(character)
		if on_play_text:
			description += "%s%s\n" % [prefix_text, on_play_text]
		var on_kill_text = CardEffect.join_effects_text(character, on_kill_effects)
		if on_kill_text:
			description += "On Kill: %s\n" % on_kill_text
	var on_play_after_text = on_play_after_effect_text(character)
	if on_play_after_text:
		description += "After Play: %s" % [on_play_after_text]
	return description

func extra_tooltips() -> Dictionary:
	var tooltips = {}
	if power_relic:
		tooltips[power_relic.name] = power_relic.tooltip
	return tooltips
