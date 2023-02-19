extends Control

class_name CardUpgrade

var chooser: CardCollectionChooser

var characters: Array[Character]
var active_character: Character

var state = StateMachine.new()
var card_to_upgrade: Card
var CHOOSE_CARD = state.add("choose_card")
var CHOOSE_UPGRADE = state.add("choose_upgrade")

var chooser_scene = preload("res://card_collection_chooser.tscn")

signal done
signal canceled

func initialize(characters: Array[Character]):
	self.characters = characters
	state.connect_signals(self)
	state.change_state(CHOOSE_CARD)

func _on_choose_card_entered():
	# Use CharacterChooser when implemented.
	active_character = characters[0]
	chooser = chooser_scene.instantiate() as CardCollectionChooser
	chooser.initialize_from_character(active_character, CardCollectionChooser.Filter.UPGRADABLE)
	chooser.connect("card_chosen", _on_card_chosen)
	add_child(chooser)

func _on_choose_card_exited():
	remove_child(chooser)
	chooser.queue_free()

func _on_choose_upgrade_entered():
	chooser = chooser_scene.instantiate() as CardCollectionChooser
	chooser.initialize_from_upgrades_to_card(active_character, card_to_upgrade)
	chooser.connect("card_chosen", _on_upgrade_card_chosen)
	add_child(chooser)

func _on_choose_upgrade_exited():
	remove_child(chooser)
	chooser.queue_free()

func _on_card_chosen(card: Card):
	card_to_upgrade = card
	state.change_state(CHOOSE_UPGRADE)

func _on_upgrade_card_chosen(card: Card):
	active_character.deck.cards.erase(card_to_upgrade)
	active_character.deck.cards.push_back(card)
	done.emit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if state.is_state(CHOOSE_CARD):
			canceled.emit()
		else:
			state.change_state(CHOOSE_CARD)
