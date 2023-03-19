extends Control

class_name CardUpgrade

@export var card_chooser: CardCollectionChooser
@export var upgrade_chooser: CardCollectionChooser
@export var card_to_upgrade_ui: CardUI
@export var upgrade_box: Control

var characters: Array[Character]
var active_character: Character

var card_to_upgrade: Card

var chooser_scene = preload("res://card_collection_chooser.tscn")

signal done(character: Character)
signal canceled

func initialize(characters: Array[Character]):
	self.characters = characters
	card_chooser.connect("card_chosen", _on_card_chosen)
	upgrade_chooser.connect("card_chosen", _on_upgrade_card_chosen)
	active_character = characters[0]
	card_chooser.initialize_from_character(active_character, CardCollectionChooser.Filter.UPGRADABLE)

func _on_card_chosen(card: Card):
	upgrade_chooser.initialize_from_upgrades_to_card(active_character, card)
	card_to_upgrade = card
	card_to_upgrade_ui.initialize(card, active_character)
	card_to_upgrade_ui.show()

func _on_upgrade_card_chosen(card: Card):
	active_character.deck.cards.erase(card_to_upgrade)
	active_character.deck.cards.push_back(card)
	done.emit(active_character)

func _input(event):
	if event.is_action_released("ui_cancel"):
		if Input.is_action_just_released("ui_cancel"):
			canceled.emit()
			accept_event()
