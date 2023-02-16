extends Control

class_name CardCollectionChooser

@export var vbox: VBoxContainer

var card_ui_scene = preload("res://card_ui.tscn")

var deck: Deck
var cards_per_row = 4  # TODO: Do something smart with screen size later.

signal card_chosen(card_idx: int)

func initialize(character: Character):
	self.deck = character.deck
	var rows = ((deck.cards.size()-1)/cards_per_row)+1
	var card_idx = 0
	for i in range(rows):
		var hbox = HBoxContainer.new()
		for d in range(cards_per_row):
			if card_idx == deck.cards.size():
				break
			var card = deck.cards[card_idx]
			var card_ui = card_ui_scene.instantiate() as CardUI
			card_ui.initialize(card, character, _on_card_pressed.bind(card_idx))
			card_idx += 1
			hbox.add_child(card_ui)
		vbox.add_child(hbox)

func _on_card_pressed(card_idx: int):
	card_chosen.emit(card_idx)
