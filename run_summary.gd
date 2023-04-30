extends Control

class_name RunSummary

@export var result: Label
@export var characters_container: Container
@export var run_stats: Control
@export var character_level_container: Container

var characters: Array
var victory: bool
var state = StateMachine.new()
var RUN_STATS = state.add("run_stats")
var CHARACTER_LEVEL = state.add("character_level")

var current_character_index: int

var character_stats_scene = preload("res://run_character_stats.tscn")
var character_level_progress_scene = preload("res://run_character_level_progress.tscn")

signal done

var xp_stats = {
	Stats.Field.COMBAT_STAGES_FINISHED: 10,
	Stats.Field.ENEMIES_KILLED: 3,
}

var finished = false

func _ready():
	state.connect_signals(self)
	state.change_state(RUN_STATS)

func initialize(characters: Array, victory: bool):
	calculate_xp(characters)
	self.characters = characters
	self.victory = victory

func _on_run_stats_entered():
	if victory:
		result.text = "Victory!"
		result.set("theme_override_colors/font_color", Color(1, 1, 1))
	else:
		result.text = "Defeat!"
		result.set("theme_override_colors/font_color", Color(1, 0, 0))
	for character in characters:
		var character_stats = character_stats_scene.instantiate() as RunCharacterStats
		character_stats.initialize(character)
		character_stats.add_stat(Stats.Field.XP)
		character_stats.add_stat(Stats.Field.COMBAT_STAGES_FINISHED)
		character_stats.add_stat(Stats.Field.ENEMIES_KILLED)
		character_stats.add_stat(Stats.Field.DAMAGE_DEALT)
		character_stats.add_stat(Stats.Field.DAMAGE_TAKEN)
		character_stats.add_stat(Stats.Field.RELICS_ACQUIRED)
		character_stats.add_stat(Stats.Field.CHESTS_ACQUIRED)
		character_stats.add_stat(Stats.Field.CARDS_ACQUIRED)
		character_stats.add_stat(Stats.Field.CARDS_UPGRADED)
		character_stats.add_stat(Stats.Field.GOLD_EARNED)
		characters_container.add_child(character_stats)

func _on_run_stats_exited():
	run_stats.hide()

func _on_character_level_entered():
	character_level_container.show()
	current_character_index = 0
	show_character_level()

func _on_character_level_exited():
	pass

func show_character_level():
	for child in character_level_container.get_children():
		child.queue_free()
	var level_progress = character_level_progress_scene.instantiate() as RunCharacterLevelProgress
	level_progress.initialize(characters[current_character_index])
	character_level_container.add_child(level_progress)

func calculate_xp(characters: Array):
	for character in characters:
		var xp = 0
		for field in xp_stats:
			var value = StatsManager.run_stats.get_value(character.character_type, field)
			xp += value * xp_stats[field]
		if xp > 0:
			StatsManager.add(character.character_type, Stats.Field.XP, xp)

func _input(event):
	if finished:
		return

	if Input.is_action_just_released("left_click"):
		if state.is_state(RUN_STATS):
			state.change_state(CHARACTER_LEVEL)
		elif state.is_state(CHARACTER_LEVEL):
			current_character_index += 1
			if current_character_index < characters.size():
				show_character_level()
			else:
				finished = true
				done.emit()
