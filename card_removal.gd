extends Control

class_name CardRemoval

@export var chooser: CardCollectionChooser

var characters: Array[Character]
var active_character: Character

signal done
signal canceled

func initialize(characters: Array[Character]):
	self.characters = characters
	# Use CharacterChooser when implemented.
	active_character = characters[0]
	chooser.initialize_from_character(active_character)
	chooser.connect("card_chosen", _on_card_chosen)

func _on_card_chosen(card: Card):
	active_character.deck.cards.erase(card)
	done.emit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		canceled.emit()
