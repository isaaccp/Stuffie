extends Control

signal run_type_selected(run_type: RunDef.RunType)
signal continue_run_selected
signal abandon_run_selected

@export var new_run_buttons: Control
@export var continue_run_buttons: Control

@export var new_game_button: Button
@export var new_game_plus_button: Button
@export var new_game_full_party_button: Button
@export var test_blacksmith_button: Button
@export var test_camp_button: Button
@export var test_after_stage_button: Button
@export var continue_run_button: Button
@export var abandon_run_button: Button

func _ready():
	new_game_button.pressed.connect(start_run.bind(RunDef.RunType.REGULAR))
	new_game_plus_button.pressed.connect(start_run.bind(RunDef.RunType.REGULAR_PLUS))
	new_game_full_party_button.pressed.connect(start_run.bind(RunDef.RunType.REGULAR_PARTY))
	test_blacksmith_button.pressed.connect(start_run.bind(RunDef.RunType.TEST_BLACKSMITH))
	test_camp_button.pressed.connect(start_run.bind(RunDef.RunType.TEST_CAMP))
	test_after_stage_button.pressed.connect(start_run.bind(RunDef.RunType.TEST_AFTER_STAGE))
	continue_run_button.pressed.connect(continue_run_button_pressed)
	abandon_run_button.pressed.connect(abandon_run_button_pressed)

func set_new_run(new_run: bool):
	if new_run:
		new_run_buttons.show()
		continue_run_buttons.hide()
	else:
		new_run_buttons.hide()
		continue_run_buttons.show()

func start_run(run_type: RunDef.RunType):
	run_type_selected.emit(run_type)

func continue_run_button_pressed():
	continue_run_selected.emit()

func abandon_run_button_pressed():
	abandon_run_selected.emit()
