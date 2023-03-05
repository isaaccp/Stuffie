extends Node

var state = StateMachine.new()
var MAIN_MENU = state.add("main_menu")
var CHARACTER_SELECT = state.add("character_select")
var WITHIN_RUN = state.add("within_run")

var main_menu_scene = preload("res://main_menu.tscn")
var character_selection_scene = preload("res://character_selection.tscn")
var game_run_scene = preload("res://game_run.tscn")

var warrior = preload("res://warrior.tscn")
var wizard = preload("res://wizard.tscn")

var character_scenes = [
	warrior,
	wizard,
]

var run_type: GameRun.RunType
var characters: Array[Character]

func _ready():
	state.connect_signals(self)
	state.change_state(MAIN_MENU)

func clear_children():
	for node in get_children():
		node.queue_free()

func _on_main_menu_entered():
	var main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	main_menu.run_type_selected.connect(select_character)

func _on_main_menu_exited():
	clear_children()

func _on_character_select_entered():
	var character_selection = character_selection_scene.instantiate() as CharacterSelection
	for character_scene in character_scenes:
		var character = character_scene.instantiate() as Character
		character_selection.characters.push_back(character)
	add_child(character_selection)
	character_selection.character_selected.connect(start_run)

func _on_character_select_exited():
	clear_children()

func _on_within_run_entered():
	StatsManager.add_level(StatsManager.Level.GAME_RUN)
	var game_run = game_run_scene.instantiate() as GameRun
	game_run.set_starting_characters(characters)
	game_run.set_run_type(run_type)
	game_run.run_finished.connect(finish_run)
	add_child(game_run)
	# Needs to be called after it's already added.
	game_run.start()

func _on_within_run_exited():
	clear_children()

func select_character(run_type: GameRun.RunType):
	self.run_type = run_type
	if run_type == GameRun.RunType.REGULAR_PARTY:
		characters.push_back(warrior.instantiate())
		characters.push_back(wizard.instantiate())
		state.change_state(WITHIN_RUN)
		return
	state.change_state(CHARACTER_SELECT)

func start_run(character: Character):
	characters.push_back(character)
	state.change_state(WITHIN_RUN)

func finish_run():
	StatsManager.remove_level(StatsManager.Level.GAME_RUN)
	state.change_state(MAIN_MENU)
