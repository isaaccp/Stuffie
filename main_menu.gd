extends Control

signal run_type_selected(run_type: GameRun.RunType)

@export var new_game_button: Button
@export var new_game_plus_button: Button
@export var new_game_full_party_button: Button
@export var test_blacksmith_button: Button
@export var test_camp_button: Button
@export var test_after_stage_button: Button

func _ready():
	new_game_button.pressed.connect(start_run.bind(GameRun.RunType.REGULAR))
	new_game_plus_button.pressed.connect(start_run.bind(GameRun.RunType.REGULAR_PLUS))
	new_game_full_party_button.pressed.connect(start_run.bind(GameRun.RunType.REGULAR_PARTY))
	test_blacksmith_button.pressed.connect(start_run.bind(GameRun.RunType.TEST_BLACKSMITH))
	test_camp_button.pressed.connect(start_run.bind(GameRun.RunType.TEST_CAMP))
	test_after_stage_button.pressed.connect(start_run.bind(GameRun.RunType.TEST_AFTER_STAGE))

func start_run(run_type: GameRun.RunType):
	run_type_selected.emit(run_type)
