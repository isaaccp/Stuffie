extends Control

class_name RunSummary

@export var result: Label
@export var characters_container: Container

var character_stats_scene = preload("res://run_character_stats.tscn")

signal done

var finished = false

func initialize(characters: Array, victory: bool):
	if victory:
		result.text = "Victory!"
		result.set("theme_override_colors/font_color", Color(1, 1, 1))
	else:
		result.text = "Defeat!"
		result.set("theme_override_colors/font_color", Color(1, 0, 0))
	for character in characters:
		var character_stats = character_stats_scene.instantiate() as RunCharacterStats
		character_stats.initialize(character)
		character_stats.add_stat(Stats.Field.COMBAT_STAGES_FINISHED)
		character_stats.add_stat(Stats.Field.ENEMIES_KILLED)
		character_stats.add_stat(Stats.Field.DAMAGE_DEALT)
		character_stats.add_stat(Stats.Field.RELICS_ACQUIRED)
		character_stats.add_stat(Stats.Field.CHESTS_ACQUIRED)
		character_stats.add_stat(Stats.Field.CARDS_UPGRADED)
		character_stats.add_stat(Stats.Field.GOLD_EARNED)
		characters_container.add_child(character_stats)

func _input(event):
	if finished:
		return

	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			finished = true
			done.emit()
