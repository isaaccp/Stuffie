extends Control

class_name CampStage

@export var choice_container: HBoxContainer
@export var camp_choices: Array[CampChoice]

# For now not using StateMachine as this stage
# will go through more changes later.
enum CampState {
	NEW_CHARACTER,
	CHOOSING,
}

var state = CampState.NEW_CHARACTER
var characters: Array[Character]
var current_character = 0
var shared_bag: SharedBag

signal stage_done

func _ready():
	pass

func initialize(characters: Array[Character], shared_bag: SharedBag):
	self.characters = characters
	self.shared_bag = shared_bag

func _process(delta):
	if state == CampState.NEW_CHARACTER:
		if current_character == characters.size():
			stage_done.emit()
			return
		var character = characters[current_character]
		var i = 0
		# TODO: Have a base choice for all characters (rest) and make other choices per
		# character.
		for choice in camp_choices:
			var button = Button.new()
			button.text = choice.title
			button.tooltip_text = choice.effect.get_description()
			button.pressed.connect(_on_button_pressed.bind(choice))
			choice_container.add_child(button)
			i += 1
		state = CampState.CHOOSING

func _next_character():
	for choice in choice_container.get_children():
		choice.queue_free()
	current_character += 1
	state = CampState.NEW_CHARACTER

func _on_button_pressed(choice: CampChoice):
	choice.effect.apply_to_character(characters[current_character])
	_next_character()
