extends Control

@export var chooser: CardCollectionChooser

func _ready():
	var characters = [
		CharacterLoader.create(Enum.CharacterId.WARRIOR),
		CharacterLoader.create(Enum.CharacterId.WIZARD),
	]
	var cards = []
	for character in characters:
		character.snap()
		for card in character.all_cards.cards:
			cards.push_back(card)
	chooser.initialize_from_cards(characters[0], cards)
	await chooser.chosen_card
