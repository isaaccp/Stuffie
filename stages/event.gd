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

var event_def: EventDef
var choice: EventChoice
var choice_effect: EventChoiceEffect

var characters: Array[Character]
var chosen_character: Character
var target_characters: Array
var shared_bag: SharedBag
var relic_list: RelicList

var portrait_scene = preload("res://character_portrait.tscn")

var state = StateMachine.new()
var CHOOSING = state.add("choosing")
var CHOOSING_TARGET = state.add("choosing_target")
var RESOLVING = state.add("resolving")

signal stage_done

func initialize(event: EventDef, characters: Array[Character], shared_bag: SharedBag, relic_list: RelicList):
	event_def = event
	self.characters = characters
	self.shared_bag = shared_bag
	self.relic_list = relic_list

func _ready():
	state.connect_signals(self)
	for character in characters:
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		character_state_ui.add_child(character_portrait)
		character_portrait.set_character(character)
		character_portrait.pressed.connect(_on_character_selected.bind(character))
	shared_bag_gold_ui.set_shared_bag(shared_bag)
	state.change_state(CHOOSING)

func _on_choosing_entered():
	# TODO: Make the UI not look so ugly.
	event_text_label.text = event_def.event_text

	match event_def.target_type:
		EventDef.TargetType.ALL_CHARACTERS:
			character_selection_label.text = "All characters event"
			refresh_choices(characters)
		EventDef.TargetType.RANDOM_CHARACTER:
			chosen_character = characters[randi() % characters.size()]
			character_selection_label.text = "Random character event: %s was selected" % chosen_character.character_name()
			refresh_choices([chosen_character])
		EventDef.TargetType.CHOOSE_CHARACTER:
			refresh_choices(characters)
			character_selection_label.text = "Choose character event: choose a character"
			for button in event_options.get_children():
				button.disabled = true

func _on_choosing_exited():
	pass

func _on_choosing_target_entered():
	for button in event_options.get_children():
		button.queue_free()
	var label = Label.new()
	label.text = choice.text
	event_options.add_child(label)
	choice_effect = choice.get_effect()
	event_resolution_label.text = choice_effect.resolution_text
	var target_characters = []
	match choice_effect.target_type:
		EventChoiceEffect.TargetType.CHOSEN_CHARACTER_OR_ALL_CHARACTERS:
			if chosen_character == null:
				resolve_effect(characters)
			else:
				resolve_effect([chosen_character])
		EventChoiceEffect.TargetType.ALL_CHARACTERS:
			resolve_effect(characters)
		EventChoiceEffect.TargetType.RANDOM_CHARACTER:
			resolve_effect([characters[randi() % characters.size()]])
		EventChoiceEffect.TargetType.CHOOSE_NEW_CHARACTER:
			event_resolution_label.text += "\nChoose a character as target for the event resolution"

func _on_choosing_target_exited():
	pass

func resolve_effect(characters: Array):
	self.target_characters = characters
	state.change_state(RESOLVING)

func _on_resolving_entered():
	if choice_effect.effects.size() != 0:
		event_resolution_label.text = choice_effect.resolution_text
		for character in target_characters:
			event_resolution_label.text += "\n%s: %s" % [character.character_name(), UnitCard.join_effects_text(character, choice_effect.effects)]
			await UnitCard.apply_effects_target(character, choice_effect.effects, character)
	done_button.show()
	done_button.pressed.connect(_on_done_pressed)

func _on_resolving_exited():
	pass

func refresh_choices(characters: Array):
	for choice in event_options.get_children():
		choice.queue_free()
	for choice in event_def.choices:
		var button = Button.new()
		var disabled = false
		if choice.preconditions.size() != 0:
			if not check_preconditions(characters, choice):
				if choice.hide_if_preconditions_fail:
					continue
				disabled = true
			var description = choice.get_preconditions_description()
			if description:
				button.text = "[%s] " % description
		button.disabled = disabled
		button.text += choice.text
		if choice.preview_choice_effects and choice.choice_effects.size() != 0:
			button.text += " (choice effect: %s)" % UnitCard.join_effects_text(null, choice.choice_effects)
		if choice.preview_resolution_effects:
			assert(choice.effects.size() == 1)
			button.text += " (resolution effect: %s)" % UnitCard.join_effects_text(null, choice.effects[0].effects)
		button.pressed.connect(_on_option_chosen.bind(choice))
		event_options.add_child(button)

func check_preconditions(characters: Array, choice: EventChoice):
	for precondition in choice.preconditions:
		if precondition.type == EventChoicePrecondition.Type.GOLD:
			if characters[0].shared_bag.gold < precondition.gold:
				return false
		elif precondition.type == EventChoicePrecondition.Type.CHARACTER_TYPE:
			var found = false
			for character in characters:
				if character.character_type in precondition.character_types:
					found = true
					break
			if not found:
				return false
		elif precondition.type == EventChoicePrecondition.Type.CARD:
			var found = false
			for character in characters:
				for card in character.deck.cards:
					if card.card_name == precondition.card.card_name or card.base_card and card.base_card.card_name == precondition.card.card_name:
						found = true
						break
			if not found:
				return false
	return true

func _on_character_selected(character: Character):
	if state.is_state(CHOOSING):
		if event_def.target_type == EventDef.TargetType.CHOOSE_CHARACTER:
			chosen_character = character
			character_selection_label.text = "Choose character event: %s currently selected" % chosen_character.character_name()
			refresh_choices([chosen_character])
	elif state.is_state(CHOOSING_TARGET):
		if choice_effect.target_type == EventChoiceEffect.TargetType.CHOOSE_NEW_CHARACTER:
			resolve_effect([character])

func _on_option_chosen(choice: EventChoice):
	self.choice = choice
	state.change_state(CHOOSING_TARGET)

func _on_done_pressed():
	stage_done.emit()

func can_save():
	return false

# Invoked when abandoning run while this stage is on.
func cleanup():
	pass