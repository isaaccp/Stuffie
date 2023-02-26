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
@export var damage_value: CardEffectValue
# Use on_play_self_effects when creating a card that has
# extra side effect on self besides target.
@export var on_play_self_effects: Array[CardEffect]
@export var on_play_effects: Array[CardEffect]
@export var on_kill_effects: Array[CardEffect]
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

func apply_on_play_effects(character: Character):
	CardEffect.apply_effects_to_character(character, on_play_effects)

func apply_self(character: Character):
	assert(target_mode == TargetMode.SELF or target_mode == TargetMode.SELF_ALLY)
	apply_on_play_effects(character)
	character.refresh()

func apply_self_effects(character: Character):
	CardEffect.apply_effects_to_character(character, on_play_self_effects)

func apply_ally(character: Character, ally: Character):
	assert(target_mode == TargetMode.SELF_ALLY or target_mode == TargetMode.ALLY)
	apply_on_play_effects(character)
	apply_self_effects(character)

func regular_damage(character: Character):
	if damage != 0:
		return damage
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

func apply_enemy(character: Character, enemy: Enemy):
	assert(target_mode == TargetMode.ENEMY or target_mode == TargetMode.AREA)
	apply_self_effects(character)
	var attack_damage = effective_damage(character)
	StatsManager.add(character, Stats.Field.DAMAGE_DEALT, attack_damage)
	enemy.hit_points -= attack_damage
	for effect in on_play_effects:
		effect.apply_to_enemy(character, enemy)
	enemy.refresh()
	if enemy.hit_points <= 0:
		CardEffect.apply_effects_to_character(character, on_kill_effects)
		return true
	return false

func is_attack():
	return damage != 0 or damage_value

func get_target_text() -> String:
	var target_text = ""
	if target_mode == Card.TargetMode.SELF:
		target_text = "self"
	elif target_mode == Card.TargetMode.SELF_ALLY:
		target_text = "self or ally"
	elif target_mode == Card.TargetMode.ALLY:
		target_text = "ally"
	elif target_mode == Card.TargetMode.AREA:
		target_text = "area"
	return target_text

func on_play_effect_text() -> String:
	return CardEffect.join_effects_text(on_play_effects)

func get_description(character: Character) -> String:
	var description = ""
	var target_text = get_target_text()
	if target_mode in [Card.TargetMode.SELF, Card.TargetMode.SELF_ALLY or Card.TargetMode.SELF_ALLY]:
		var on_play_text = on_play_effect_text()
		if on_play_text:
			description += "On Play(%s): %s" % [target_text, on_play_text]
	elif target_mode in [Card.TargetMode.ENEMY, Card.TargetMode.AREA]:
		var attack_text = "Attack"
		var area_size = effect_area(Vector2.RIGHT).size()
		if area_size > 1:
			attack_text += (" enemies in area (%s tiles)" % area_size)
		var damage = regular_damage(character)
		if damage:
			var damage_text = "%d" % damage
			if damage != effective_damage(character):
				damage_text = "%d ([color=red]%d[/color])" % [damage, effective_damage(character)]
			description += "%s for %s dmg\n" % [attack_text, damage_text]
		var on_play_text = on_play_effect_text()
		if on_play_text:
			description += "On Play(%s): %s" % [target_text, on_play_text]
		var on_play_self_text = CardEffect.join_effects_text(on_play_self_effects)
		if on_play_self_text:
			description += "On Play: %s" % on_play_self_text
		var on_kill_text = CardEffect.join_effects_text(on_kill_effects)
		if on_kill_text:
			description += "On Kill: %s" % on_kill_text
	return description
