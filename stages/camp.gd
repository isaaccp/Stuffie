extends Control

class_name CampStage

@export var character_portrait: CharacterPortrait
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
	for character in characters:
		StatsManager.add(character, Stats.Field.CAMPS_VISITED, 1)

func add_choice(character: Character, choice: CampChoice):
	var button = Button.new()
	button.text = choice.title
	button.tooltip_text = CardEffect.join_effects_text(character, choice.effects)
	button.pressed.connect(_on_button_pressed.bind(choice))
	choice_container.add_child(button)

func _process(delta):
	if state == CampState.NEW_CHARACTER:
		if current_character == characters.size():
			stage_done.emit()
			return
		var character = characters[current_character]
		character_portrait.set_character(character)
		var i = 0
		# TODO: Have a base choice for all characters (rest) and make other choices per
		# character.
		for choice in camp_choices:
			add_choice(character, choice)
		for choice in character.camp_choices():
			add_choice(character, choice)
		state = CampState.CHOOSING

func _next_character():
	for choice in choice_container.get_children():
		choice.queue_free()
	current_character += 1
	state = CampState.NEW_CHARACTER

func _on_button_pressed(choice: CampChoice):
	for effect in choice.effects:
		effect.apply_to_character(characters[current_character])
	_next_character()

func can_save():
	return false
