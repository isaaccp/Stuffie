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
var one_off = true

signal character_selected(character: Character)

func _ready():
	var i = 0
	for character  in characters:
		var portrait = portrait_scene.instantiate() as CharacterPortrait
		portrait.set_character(character)
		portrait.portrait.pressed.connect(_on_character_portrait_pressed.bind(i))
		character_container.add_child(portrait)
		i += 1
	if not one_off:
		_modulate(0)

func _modulate(index: int):
	var i = 0
	for portrait in character_container.get_children():
		if i == index:
			portrait.modulate = Color(1.0, 1.0, 1.0)
		else:
			portrait.modulate = Color(0.5, 0.5, 0.5)
		i += 1

func _on_character_portrait_pressed(index: int):
	if not one_off:
		_modulate(index)
	character_selected.emit(characters[index])
