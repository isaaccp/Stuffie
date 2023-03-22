extends RefCounted

class_name RelicActuator

var character: Character
var relic_manager: RelicManager

func _init(character: Character):
	self.character = character
	self.relic_manager = character.relic_manager
	connect_signals()

func connect_signals():
	character.stage_started.connect(_on_start_stage)
	character.stage_ended.connect(_on_end_stage)
	character.attacked.connect(_on_attack)
	character.turn_started.connect(_on_start_turn)
	character.turn_ended.connect(_on_end_turn)
	character.card_played.connect(_on_card_played)
	StatsManager.stats_added.connect(_on_stats_added.bind(character))

func apply_damage_change(character: Character, damage: int):
	var dmg = damage
	for relic_list in [relic_manager.relics, relic_manager.temp_relics]:
		for relic in relic_list:
			dmg = relic.apply_damage_change(character, dmg)
	return dmg

func camp_choices() -> Array:
	var choices = []
	# temp_relics don't live across stages
	for relic in relic_manager.relics:
		for choice in relic.camp_choices():
			choices.push_back(choice)
	return choices

func _call_all_relics(method_name: String, args: Array):
	for relic_list in [relic_manager.relics, relic_manager.temp_relics]:
		for relic in relic_list:
			relic.callv(method_name, args)

func _on_start_stage(character: Character):
	_call_all_relics("_on_start_stage", [character])

func _on_end_stage(character: Character):
	_call_all_relics("_on_end_stage", [character])

func _on_attack(character: Character):
	_call_all_relics("_on_attack", [character])

func _on_start_turn(character: Character):
	_call_all_relics("_on_start_turn", [character])

func _on_end_turn(character: Character):
	_call_all_relics("_on_end_turn", [character])

func _on_card_played(character: Character, card: Card):
	_call_all_relics("_on_card_played", [character, card])

func _on_stats_added(character_type: Enum.CharacterId, field: Stats.Field, value: int, character: Character):
	if character_type == character.character_type:
		_call_all_relics("_on_stats_added", [character, field, value])