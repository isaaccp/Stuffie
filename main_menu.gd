extends Control

signal new_game_selected
signal test_blacksmith_selected

@export var new_game_button: Button
@export var test_blacksmith_button: Button

func _ready():
	new_game_button.connect("pressed", new_game_pressed)
	test_blacksmith_button.connect("pressed", test_blacksmith_pressed)

func new_game_pressed():
	new_game_selected.emit()

func test_blacksmith_pressed():
	test_blacksmith_selected.emit()
