extends Control

class_name EventStage

@export var event_text_area: Control
@export var event_text_label: RichTextLabel
@export var event_options: Container
@export var character_selection_label: Label
@export var event_resolution_label: RichTextLabel
@export var character_state_ui: Container
@export var shared_bag_gold_ui: SharedBagGoldUI
@export var done_button: Button

# Eventually we'll need some fancier way to get events (e.g. depending on level, etc)
@export var events: Array[EventDef]

var event_def: EventDef
var choice: EventChoice

var characters: Array[Character]
var chosen_character: Character
var shared_bag: SharedBag
var relic_list: RelicList

var portrait_scene = preload("res://character_portrait.tscn")

var state = StateMachine.new()
var CHOOSING_CHARACTER = state.add("choosing_character")
var CHOOSING_OPTION = state.add("choosing_option")
var RESOLUTION = state.add("resolution")

signal stage_done
signal _character_chosen

func initialize(characters: Array[Character], shared_bag: SharedBag, relic_list: RelicList):
	event_def = events[randi() % events.size()]
	self.characters = characters
	self.shared_bag = shared_bag
	self.relic_list = relic_list

func _ready():
	for character in characters:
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		character_state_ui.add_child(character_portrait)
		character_portrait.set_character(character)
		character_portrait.pressed.connect(_on_character_selected.bind(character))
	shared_bag_gold_ui.set_shared_bag(shared_bag)
	start.call_deferred()

func _on_character_selected(character: Character):
	chosen_character = character
	_character_chosen.emit()

func start():
	# TODO: Make all this not look so ugly.
	event_text_label.text = event_def.event_text
	for choice in event_def.choices:
		var button = Button.new()
		button.text = choice.text
		button.pressed.connect(_on_option_chosen.bind(choice))
		event_options.add_child(button)
	match event_def.target_type:
		EventDef.TargetType.ALL_CHARACTERS:
			character_selection_label.text = "All characters are involved in this event"
		EventDef.TargetType.RANDOM_CHARACTER:
			chosen_character = characters[randi() % characters.size()]
			character_selection_label.text = "%s is involved in this event" % chosen_character.character_name()
		EventDef.TargetType.CHOOSE_CHARACTER:
			character_selection_label.text = "Select a character to be involved in this event"
			for button in event_options.get_children():
				button.disabled = true
			await _character_chosen
			character_selection_label.text = "%s is involved in this event" % chosen_character.character_name()
			for button in event_options.get_children():
				button.disabled = false

func _on_option_chosen(choice: EventChoice):
	self.choice = choice

	for button in event_options.get_children():
		button.queue_free()
	var label = Label.new()
	label.text = choice.text
	event_options.add_child(label)
	var effect = choice.get_effect()
	event_resolution_label.text = effect.resolution_text
	var target_characters = []
	match effect.target_type:
		EventChoiceEffect.TargetType.CHOSEN_CHARACTER_OR_ALL_CHARACTERS:
			if chosen_character == null:
				target_characters = characters
			else:
				target_characters = [chosen_character]
		EventChoiceEffect.TargetType.ALL_CHARACTERS:
			target_characters = characters
		EventChoiceEffect.TargetType.RANDOM_CHARACTER:
			target_characters = [characters[randi() % characters.size()]]
		EventChoiceEffect.TargetType.CHOOSE_NEW_CHARACTER:
			event_resolution_label.text += "\nChoose a character as target for the event resolution"
			await _character_chosen
			target_characters = [chosen_character]
	if effect.effects.size() != 0:
		event_resolution_label.text = effect.resolution_text
		for character in target_characters:
			event_resolution_label.text += "\n%s: %s" % [character.character_name(), UnitCard.join_effects_text(character, effect.effects)]
			await UnitCard.apply_effects_target(character, effect.effects, character)
	done_button.show()
	done_button.pressed.connect(_on_done_pressed)

func _on_done_pressed():
	stage_done.emit()

func can_save():
	return false

# Invoked when abandoning run while this stage is on.
func cleanup():
	pass
