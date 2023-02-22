extends PanelContainer

class_name CardCollectionChooser

@export var vbox: VBoxContainer

enum Filter {
	ALL,
	UPGRADABLE,
}

var card_ui_scene = preload("res://card_ui.tscn")

var cards: Array
var cards_per_row = 4  # TODO: Do something smart with screen size later.

signal card_chosen(card: Card)

func reset():
	cards.clear()
	for child in vbox.get_children():
		child.queue_free()

func initialize_from_character(character: Character, filter=Filter.ALL):
	if filter == Filter.ALL:
		initialize_from_cards(character, character.deck.cards)
	elif filter == Filter.UPGRADABLE:
		var upgradable_cards: Array[Card] = []
		for card in character.deck.cards:
			if character.card_upgrades.has(card.card_name):
				upgradable_cards.push_back(card)
		initialize_from_cards(character, upgradable_cards)

func initialize_from_upgrades_to_card(character: Character, card: Card):
	var upgrades = character.card_upgrades[card.card_name].duplicate()
	initialize_from_cards(character, upgrades)

func initialize_from_cards(character: Character, cards: Array):
	reset()
	self.cards = cards
	var rows = ((cards.size()-1)/cards_per_row)+1
	var card_idx = 0
	for i in range(rows):
		var hbox = HBoxContainer.new()
		for d in range(cards_per_row):
			if card_idx == cards.size():
				break
			var card = cards[card_idx]
			var card_ui = card_ui_scene.instantiate() as CardUI
			card_ui.initialize(card, character, _on_card_pressed.bind(card_idx))
			card_idx += 1
			hbox.add_child(card_ui)
		vbox.add_child(hbox)

func _on_card_pressed(card_idx: int):
	card_chosen.emit(cards[card_idx])
