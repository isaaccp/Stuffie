extends Control

class_name CharacterSelection

@export var character_container: Container

var warrior = preload("res://warrior.tscn")
var wizard = preload("res://wizard.tscn")

var character_scenes = [
	warrior,
	wizard,
]

var characters = []
var portrait_scene = preload("res://character_portrait.tscn")

signal character_selected(character: Character)

func _ready():
	var i = 0
	for character_scene in character_scenes:
		var portrait = portrait_scene.instantiate() as CharacterPortrait
		var character = character_scene.instantiate() as Character
		characters.push_back(character)
		portrait.set_character(character)
		portrait.portrait.pressed.connect(_on_character_portrait_pressed.bind(i))
		character_container.add_child(portrait)
		i += 1

func _on_character_portrait_pressed(index: int):
	print_debug(characters)
	character_selected.emit(characters[index])
