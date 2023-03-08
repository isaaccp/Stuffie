extends Control

@export var label: Label
@export var card_container: HBoxContainer
@export var skip: Button
@export var character_portrait: CharacterPortrait

# For now not using StateMachine as this stage
# will go through more changes later.
enum BetweenStagesState {
	NEW_CHARACTER,
	CHOOSING,
	DONE,
}

const default_options = 3

var state = BetweenStagesState.NEW_CHARACTER

var characters: Array[Character]
var current_character = 0
var current_cards: Array[Card]
var card_ui_scene = preload("res://card_ui.tscn")
var shared_bag: SharedBag
var options: int

const NO_CARD_GOLD = 5

signal between_stages_done(stats: Stats)

func _ready():
	pass

func initialize(characters: Array[Character], shared_bag: SharedBag, options=default_options):
	self.characters = characters
	self.shared_bag = shared_bag
	self.options = options

func _process(delta):
	if state == BetweenStagesState.NEW_CHARACTER:
		var character = characters[current_character]
		character_portrait.set_character(character)
		current_cards = character.extra_cards.choose(options)
		var i = 0
		for card in current_cards:
			var new_card = card_ui_scene.instantiate() as CardUI
			new_card.initialize(card, character, _on_card_pressed.bind(i))
			card_container.add_child(new_card)
			i += 1
		skip.text = "Skip (get %d🪙)" % NO_CARD_GOLD
		skip.pressed.connect(_on_skip_pressed)
		state = BetweenStagesState.CHOOSING

func _next_character():
	for card in card_container.get_children():
		card.queue_free()
	current_character += 1
	if current_character < characters.size():
		state = BetweenStagesState.NEW_CHARACTER
	else:
		state = BetweenStagesState.DONE
		between_stages_done.emit()


func _on_card_pressed(card_number: int):
	characters[current_character].deck.add_card(current_cards[card_number])
	StatsManager.add(characters[current_character], Stats.Field.CARDS_ACQUIRED, 1)
	_next_character()

func _on_skip_pressed():
	shared_bag.add_gold(NO_CARD_GOLD)
	StatsManager.add(characters[current_character], Stats.Field.GOLD_EARNED, NO_CARD_GOLD)
	_next_character()
