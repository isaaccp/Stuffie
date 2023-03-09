extends Node

var state = StateMachine.new()
var MAIN_MENU = state.add("main_menu")
var CHARACTER_SELECT = state.add("character_select")
var WITHIN_RUN = state.add("within_run")
var PROGRESS = state.add("progress")
var ABANDON_RUN = state.add("abandon_run")

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
var game_run: GameRun
var characters: Array[Character]
var loaded_save_state: SaveState
var save_state_within_run = false

func _ready():
	state.connect_signals(self)
	load_game_state()
	state.change_state(MAIN_MENU)

func clear_children():
	for node in get_children():
		node.queue_free()

func _on_main_menu_entered():
	var main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	main_menu.set_new_run(not save_state_within_run)
	main_menu.run_type_selected.connect(select_character)
	main_menu.continue_run_selected.connect(continue_run)
	main_menu.abandon_run_selected.connect(abandon_run)

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
	game_run = game_run_scene.instantiate()
	add_child(game_run)
	if save_state_within_run:
		game_run.load_save_state(loaded_save_state.run_state)
	else:
		StatsManager.add_level(StatsManager.Level.GAME_RUN)
		game_run.set_run_type(run_type)
		game_run.set_starting_characters(characters)
		game_run.start()
	game_run.run_finished.connect(finish_run)

func _on_within_run_exited():
	clear_children()

func _on_progress_entered():
	# Load a nice view of progress when ready.
	# Character unlocks are based on certain achievements
	# (e.g., receive 1000 damage, obtain 500 block, etc)
	# Display progress towards those, new unlocks, etc.
	progress.call_deferred()

func progress():
	StatsManager.remove_level(StatsManager.Level.GAME_RUN)
	save_game_state()
	state.change_state(MAIN_MENU)

func _on_progress_exited():
	pass

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
	state.change_state(PROGRESS)

func continue_run():
	state.change_state(WITHIN_RUN)

func abandon_run():
	state.change_state(ABANDON_RUN)

func _on_abandon_run_entered():
	# Do something better here, like showing progress. Probably can be
	# merged with PROGRESS state.
	save_state_within_run = false
	StatsManager.stats.trim_to_level(StatsManager.Level.GAME_RUN)
	# Show progress, then.
	StatsManager.stats.trim_to_level(StatsManager.Level.OVERALL)
	save_game_state()
	state.change_state.call_deferred(MAIN_MENU)

func _on_abandon_run_exited():
	pass

func load_game_state():
	if not FileAccess.file_exists("user://stuffie_save.tres"):
		return
	loaded_save_state = load("user://stuffie_save.tres") as SaveState
	StatsManager.stats = loaded_save_state.stats
	if loaded_save_state.main_game_state == WITHIN_RUN.name:
		StatsManager.stats.trim_to_level(StatsManager.Level.GAME_RUN)
		save_state_within_run = true

func save_game_state():
	var save_state = SaveState.new()
	save_state.stats = StatsManager.stats
	save_state.main_game_state = state.current_state_name()
	if state.is_state(WITHIN_RUN):
		save_state.run_state = game_run.get_save_state()

	ResourceSaver.save(save_state, "user://stuffie_save.tres")
