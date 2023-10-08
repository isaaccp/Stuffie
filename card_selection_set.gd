@tool
extends Resource

class_name CardSelectionSet

# Set of cards in the deck.
@export var cards: Array[Card]

func _ready():
	# Check for uniqueness.
	var names = Dictionary()
	for card in cards:
		if names.has(card.card_name):
			assert(false)

func choose(number: int) -> Array[Card]:
	cards.shuffle()
	return cards.slice(0, number, 1, true)
