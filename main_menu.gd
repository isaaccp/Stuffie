extends Control

signal new_game_selected

@export var new_game_button: Button

func _ready():
	new_game_button.connect("pressed", new_game_pressed)

func new_game_pressed():
	new_game_selected.emit()
