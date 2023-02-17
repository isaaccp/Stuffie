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
	chooser.initialize(active_character)
	chooser.connect("card_chosen", _on_card_chosen)

func _on_card_chosen(card_idx: int):
	active_character.deck.cards.remove_at(card_idx)
	done.emit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		canceled.emit()
