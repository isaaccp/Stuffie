extends Resource

class_name Deck

# Set of cards in the deck.
@export var cards: Array[Card]
# Current cards in deck during stage.
var deck: Array[Card]
# Current cards in hand during stage.
var hand: Array[Card]
# Current cards in discard pile during stage.
var discard: Array[Card]

func reset():
	deck.clear()
	hand.clear()
	discard.clear()
	for card in cards:
		deck.push_back(card)
	shuffle()

func add_card(card: Card):
	cards.push_back(card)

func shuffle():
	deck.shuffle()

func draw_card():
	if deck.is_empty():
		shuffle_discard()
	hand.append(deck.pop_back())

func draw_cards(num_cards: int):
	for i in num_cards:
		draw_card()

func draw_attack(num_cards: int):
	var drawn = 0
	for card in deck:
		if card.is_attack():
			deck.erase(card)
			hand.append(card)
			drawn += 1
			if drawn == num_cards:
				return

func num_hand_cards():
	return hand.size()

func shuffle_discard():
	while not discard.is_empty():
		deck.append(discard.pop_back())
	shuffle()

func discard_card(index: int):
	discard.append(hand.pop_at(index))

func discard_hand():
	while not hand.is_empty():
		discard.append(hand.pop_back())

func stage_deck_size():
	return deck.size()
