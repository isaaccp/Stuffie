extends Control

signal run_type_selected(run_type: GameRun.RunType)

@export var new_game_button: Button
@export var test_blacksmith_button: Button
@export var test_camp_button: Button

func _ready():
	new_game_button.pressed.connect(start_run.bind(GameRun.RunType.REGULAR))
	test_blacksmith_button.pressed.connect(start_run.bind(GameRun.RunType.TEST_BLACKSMITH))
	test_camp_button.pressed.connect(start_run.bind(GameRun.RunType.TEST_CAMP))

func start_run(run_type: GameRun.RunType):
	run_type_selected.emit(run_type)
