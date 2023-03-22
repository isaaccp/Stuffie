extends RefCounted

class_name UnitCard

var unit: Unit
var card: Card

func _init(unit: Unit, card: Card):
	self.unit = unit
	self.card = card

func apply_on_play_effects(target: Unit):
	await apply_effects_target(card.on_play_effects, target)

func apply_self():
	assert(card.target_mode == Enum.TargetMode.SELF or card.target_mode == Enum.TargetMode.SELF_ALLY)
	if card.power_relic:
		# Only character implements this.
		if unit.has_method("add_temp_relic"):
			unit.add_temp_relic(card.power_relic)
	await apply_on_play_effects(unit)
	unit.refresh()

func apply_self_effects():
	await apply_effects_target(card.on_play_self_effects, unit)

func apply_after_effects():
	await apply_effects_target(card.on_play_after_effects, unit)

func apply_to_ally(ally: Unit):
	assert(card.target_mode == Enum.TargetMode.SELF_ALLY or card.target_mode == Enum.TargetMode.ALLY)
	await apply_effects_target(card.on_play_effects, ally)
	await apply_self_effects()

func apply_to_enemy(enemy: Unit):
	assert(card.target_mode == Enum.TargetMode.ENEMY or card.target_mode == Enum.TargetMode.AREA)
	var attack_damage = effective_damage()
	unit.add_stat(Stats.Field.DAMAGE_DEALT, attack_damage)
	enemy.apply_damage(attack_damage)
	for effect in card.on_play_effects:
		apply_effect_target(effect, enemy)
	enemy.refresh()
	if enemy.hit_points <= 0:
		apply_effects_target(card.on_kill_effects, unit)
		return true
	return false
func regular_damage():
	if card.damage_value:
		return get_effect_value(card.damage_value)
	return 0

func effective_damage():
	# Cards with natural 0 damage are not intended to be attacks.
	if regular_damage() == 0:
		return 0
	var new_damage = regular_damage()
	if unit.has_method("apply_relic_damage_change"):
		new_damage = unit.apply_relic_damage_change(new_damage)
	if unit.power > 0:
		new_damage *= 1.5
	return int(new_damage)

func get_damage_description():
	if card.damage_value == null:
		return ""
	var damage = regular_damage()
	var damage_text = "%d" % damage
	if card.damage_value:
		damage_text = get_effect_value_string(card.damage_value)
	var effective_damage = effective_damage()
	if damage != effective_damage:
			damage_text = "%s ([color=red]%d[/color])" % [damage_text, effective_damage]
	return damage_text

func get_target_text() -> String:
	var target_text = ""
	if card.target_mode == Enum.TargetMode.SELF:
		target_text = "Self"
	elif card.target_mode == Enum.TargetMode.SELF_ALLY:
		target_text = "Self or Ally"
	elif card.target_mode == Enum.TargetMode.ALLY:
		target_text = "Ally"
	elif card.target_mode == Enum.TargetMode.ENEMY:
		target_text = "Enemy"
	elif card.target_mode == Enum.TargetMode.AREA:
		var area_size = card.effect_area(Vector2.RIGHT).size()
		target_text = "Area (%d tiles)" % area_size
	return target_text

func on_play_effect_text() -> String:
	return UnitCard.join_effects_text(unit, card.on_play_effects)

func on_play_after_effect_text() -> String:
	return UnitCard.join_effects_text(unit, card.on_play_after_effects)

func get_description() -> String:
	var description = ""
	if card.should_exhaust():
		description = "[url=exhaust]Exhaust[/url]. "
	var target_text = get_target_text()
	var prefix_text = ""
	if target_text != "Self":
		prefix_text = "%s: " % target_text
	if card.target_mode in [Enum.TargetMode.SELF, Enum.TargetMode.SELF_ALLY or Enum.TargetMode.SELF_ALLY]:
		if card.power_relic:
			description += "Power: [url]%s[/url]\n" % card.power_relic.name
		var on_play_text = on_play_effect_text()
		if on_play_text:
			description += "%s%s\n" % [prefix_text, on_play_text]
	elif card.target_mode in [Enum.TargetMode.ENEMY, Enum.TargetMode.AREA]:
		var on_play_self_text = UnitCard.join_effects_text(unit, card.on_play_self_effects)
		if on_play_self_text:
			description += "Before Play: %s\n" % on_play_self_text
		var attack_text = "Attack"
		var area_size = card.effect_area(Vector2.RIGHT).size()
		if area_size > 1:
			attack_text += (" enemies in area (%s tiles)" % area_size)
		var damage_text = get_damage_description()
		if damage_text:
			description += "%s for %s dmg\n" % [attack_text, damage_text]
		var on_play_text = on_play_effect_text()
		if on_play_text:
			description += "%s%s\n" % [prefix_text, on_play_text]
		var on_kill_text = UnitCard.join_effects_text(unit, card.on_kill_effects)
		if on_kill_text:
			description += "On Kill: %s\n" % on_kill_text
	var on_play_after_text = on_play_after_effect_text()
	if on_play_after_text:
		description += "After Play: %s" % [on_play_after_text]
	return description

# CardEffect

# All stats are updated inside the character methods. That way objects like relics that don't use
# CardEffect will still update stats easily.
func apply_effect_target(effect: CardEffect, target: Unit):
	var value = 0
	# Some effects don't need a value, so allow that.
	if effect.effect_value:
		value = get_effect_value(effect.effect_value)
	if effect.effect_type == CardEffect.EffectType.EFFECT:
		match effect.effect:
			CardEffect.Effect.DISCARD_HAND:
				target.discard_hand()
			CardEffect.Effect.DRAW_CARDS:
				target.draw_cards(value)
			CardEffect.Effect.DRAW_ATTACKS:
				target.draw_attacks(value)
			CardEffect.Effect.PICK_CARDS:
				await target.pick_cards(value)
			CardEffect.Effect.PICK_ATTACKS:
				await target.pick_attacks(value)
			CardEffect.Effect.COLLECTION_UPGRADE:
				# TODO: This ignores value and just upgrades one as of now.
				await target.upgrade_cards(value)
			CardEffect.Effect.TELEPORT:
				# TODO: Assert this is not invoked outside of combat.
				await target.teleport(value)
			CardEffect.Effect.DUPLICATE_CARD:
				await target.duplicate_cards(value, effect.metadata)
	elif effect.effect_type == CardEffect.EffectType.FIELD:
		match effect.target_field:
			CardEffectValue.Field.ACTION_POINTS: target.action_points += value
			CardEffectValue.Field.HIT_POINTS:
				target.heal(value)
			CardEffectValue.Field.TOTAL_HIT_POINTS:
					target.total_hit_points += value
					target.heal(value)
			CardEffectValue.Field.BLOCK:
				target.add_block(value)
			CardEffectValue.Field.DODGE:
				target.add_dodge(value)
			CardEffectValue.Field.POWER:
				target.add_power(value)
			CardEffectValue.Field.GOLD:
				target.add_gold(value)
			CardEffectValue.Field.MOVE_POINTS:
				target.move_points += value
				if value < 0:
					unit.add_stat(Stats.Field.ENEMY_MP_REMOVED, value)
			CardEffectValue.Field.WEAKNESS:
				target.weakness += value
				unit.add_stat(Stats.Field.WEAKNESS_APPLIED, value)
			CardEffectValue.Field.PARALYSIS:
				target.paralysis += value
				unit.add_stat(Stats.Field.PARALYSIS_APPLIED, value)

func get_effect_description(effect: CardEffect) -> String:
	var effect_text = ""
	var value_text = ""
	if effect.effect_value:
		value_text = effect.effect_value.get_value_string(unit)
	if effect.effect_type == CardEffect.EffectType.EFFECT:
		match effect.effect:
			CardEffect.Effect.DISCARD_HAND: effect_text = "discard your hand"
			CardEffect.Effect.DRAW_CARDS: effect_text = "draw %s cards" % value_text
			CardEffect.Effect.DRAW_ATTACKS: effect_text = "draw %s attack cards" % value_text
			CardEffect.Effect.PICK_CARDS: effect_text = "shuffle discard into deck and pick %s cards" % value_text
			CardEffect.Effect.PICK_ATTACKS: effect_text = "shuffle discard into deck and pick %s attack cards" % value_text
			CardEffect.Effect.COLLECTION_UPGRADE: effect_text = "upgrade %s cards" % value_text
			CardEffect.Effect.TELEPORT: effect_text = "teleport up to %s tiles" % value_text
			CardEffect.Effect.DUPLICATE_CARD: effect_text = "copy %s (%s)\n%s" % [effect.metadata_card_filter(), value_text, effect.metadata_extra_description()]
	elif effect.effect_type == CardEffect.EffectType.FIELD:
		var prefix_text = "add"
		if effect.effect_value.is_negative():
			prefix_text = "remove"
			# Remove leading -.
			value_text = value_text.substr(1)
		effect_text = "%s %s %s" % [prefix_text, value_text, CardEffectValue.get_regular_field_name(effect.target_field)]
	return effect_text

static func join_effects_text(unit: Unit, effects: Array[CardEffect]) -> String:
	var effect_texts: PackedStringArray = []
	for effect in effects:
		var description = unit.get_effect_description(effect)
		if effect_texts.size() == 0:
			description = description[0].to_upper() + description.substr(1,-1)
		effect_texts.push_back(description)
	return ', '.join(effect_texts)

func apply_effects_target(effects: Array[CardEffect], target: Unit):
	for effect in effects:
		await apply_effect_target(effect, target)

# CardEffectValue

func get_effect_value(effect_value: CardEffectValue):
	if effect_value.value_type == CardEffectValue.ValueType.ABSOLUTE:
		return effect_value.absolute_value
	if effect_value.value_type == CardEffectValue.ValueType.REFERENCE:
		var original_value = _get_effect_reference_value(effect_value)
		return int(original_value * effect_value.reference_fraction)

func _get_effect_reference_value(effect_value: CardEffectValue):
	if effect_value.value_field_type == CardEffectValue.ValueFieldType.REGULAR:
		return get_field(effect_value.regular_field)
	elif effect_value.value_field_type == CardEffectValue.ValueFieldType.READ_ONLY:
		return get_read_only_field(effect_value.read_only_field)

func get_field(field: CardEffectValue.Field):
	match field:
		CardEffectValue.Field.TOTAL_HIT_POINTS: return unit.total_hit_points
		CardEffectValue.Field.BLOCK: return unit.block
	assert(false)

func get_read_only_field(field: CardEffectValue.ReadOnlyField):
	match field:
		CardEffectValue.ReadOnlyField.SNAPSHOT_HAND_CARDS: return unit.snapshot.num_hand_cards
	assert(false)

func get_effect_value_string(effect_value: CardEffectValue):
	if effect_value.value_type == CardEffectValue.ValueType.ABSOLUTE:
		return "%d" % effect_value.absolute_value
	if effect_value.value_type == CardEffectValue.ValueType.REFERENCE:
		return "%d%% of %s (%d)" % [effect_value.reference_fraction * 100, effect_value.get_field_name(), get_effect_value(effect_value)]

func is_negative(effect_value: CardEffectValue):
	if effect_value.value_type == CardEffectValue.ValueType.ABSOLUTE and effect_value.absolute_value < 0:
		return true
	if effect_value.value_type == CardEffectValue.ValueType.REFERENCE and effect_value.reference_fraction < 0:
		return true
	return false
