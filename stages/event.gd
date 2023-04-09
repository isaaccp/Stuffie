extends Control

class_name EventStage

@export var event_text_area: Control
@export var event_text_label: RichTextLabel
@export var event_options: Container
@export var event_resolution_label: RichTextLabel
@export var character_state_ui: Container
@export var shared_bag_gold_ui: SharedBagGoldUI
@export var done_button: Button

# Eventually we'll need some fancier way to get events (e.g. depending on level, etc)
@export var events: Array[EventDef]

var event_def: EventDef
var choice: EventChoice

var characters: Array[Character]
var active_character: Character
var shared_bag: SharedBag
var relic_list: RelicList

var portrait_scene = preload("res://character_portrait.tscn")

signal stage_done

func _ready():
	for character in characters:
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		character_state_ui.add_child(character_portrait)
		character_portrait.set_character(character)
	shared_bag_gold_ui.set_shared_bag(shared_bag)
	event_text_label.text = event_def.event_text
	for choice in event_def.choices:
		var button = Button.new()
		button.text = choice.text
		button.pressed.connect(_on_option_chosen.bind(choice))
		event_options.add_child(button)
	# TODO: Make all this not look so ugly.

func initialize(characters: Array[Character], shared_bag: SharedBag, relic_list: RelicList):
	event_def = events[randi() % events.size()]
	self.characters = characters
	self.shared_bag = shared_bag
	self.relic_list = relic_list

func _on_option_chosen(choice: EventChoice):
	self.choice = choice

	for button in event_options.get_children():
		button.queue_free()
	var label = Label.new()
	label.text = choice.text
	event_options.add_child(label)
	var effect = choice.get_effect()
	event_resolution_label.text = effect.resolution_text
	for character in characters:
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
