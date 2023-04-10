extends Control

class_name CardRemoval

@export var chooser: CardCollectionChooser

var characters: Array[Character]
var active_character: Character
var cancelable: bool

signal done(character: Character)
signal canceled

func initialize(characters: Array[Character], cancelable = true):
	self.cancelable = cancelable
	self.characters = characters
	# Use CharacterChooser when implemented.
	active_character = characters[0]
	chooser.initialize_from_character(active_character)
	chooser.connect("card_chosen", _on_card_chosen)

func _on_card_chosen(card: Card):
	active_character.deck.cards.erase(card)
	done.emit(active_character)

func _input(event):
	if cancelable:
		if event.is_action_pressed("ui_cancel"):
			canceled.emit()
