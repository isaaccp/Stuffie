extends Control

@export var label: Label
@export var card_container: HBoxContainer

enum BetweenStagesState {
	NEW_CHARACTER,
	CHOOSING,
	DONE,
}

const num_cards_selection = 3

var state = BetweenStagesState.NEW_CHARACTER
var characters: Array[Character]
var current_character = 0
var current_cards: Array[Card]
var card_ui_scene = preload("res://card_ui.tscn")

signal between_stages_done

func _ready():
	pass

func initialize(characters: Array[Character]):
	self.characters = characters
	
func _process(delta):
	if state == BetweenStagesState.NEW_CHARACTER:
		if current_character == characters.size():
			between_stages_done.emit()
			state = BetweenStagesState.DONE
			return
		var character = characters[current_character]
		current_cards = character.extra_cards.choose(num_cards_selection)
		var i = 0
		for card in current_cards:
			var new_card = card_ui_scene.instantiate() as CardUI
			new_card.initialize(card, character, _on_card_pressed.bind(i))
			card_container.add_child(new_card)
			i += 1
		state = BetweenStagesState.CHOOSING

func _on_card_pressed(card_number: int):
	characters[current_character].deck.add_card(current_cards[card_number])
	for card in card_container.get_children():
		card.queue_free()
	current_character += 1
	state = BetweenStagesState.NEW_CHARACTER

