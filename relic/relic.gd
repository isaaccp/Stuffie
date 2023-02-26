extends Resource

class_name Relic

@export var name: String
@export var tooltip: String

func connect_signals(character: Character):
	character.stage_started.connect(_on_start_stage)
	character.stage_ended.connect(_on_end_stage)
	character.attacked.connect(_on_attack)
	character.turn_started.connect(_on_start_turn)
	character.turn_ended.connect(_on_end_turn)
	StatsManager.stats_added.connect(_on_stats_added)

func _on_start_stage(character: Character):
	pass

func _on_end_stage(character: Character):
	pass

func _on_attack(character: Character):
	pass

func _on_start_turn(character: Character):
	pass

func _on_end_turn(character: Character):
	pass

func _on_stats_added(character: Character, field: Stats.Field, value: int):
	pass

func camp_choices():
	return []

func apply_damage_change(damage: int, character: Character):
	return damage
