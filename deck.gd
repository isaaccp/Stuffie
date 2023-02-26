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
	var drawn = 0
	for card in deck:
		deck.erase(card)
		hand.append(card)
		drawn += 1
		if drawn == num_cards:
			break
	return drawn

func draw_attacks(num_cards: int):
	var drawn = 0
	for card in deck:
		if card.is_attack():
			deck.erase(card)
			hand.append(card)
			drawn += 1
			if drawn == num_cards:
				break
	return drawn


func num_hand_cards():
	return hand.size()

func shuffle_discard():
	while not discard.is_empty():
		deck.append(discard.pop_back())
	shuffle()

func discard_card(index: int):
	discard.append(hand.pop_at(index))

func discard_hand():
	var discarded = 0
	while not hand.is_empty():
		discard.append(hand.pop_back())
		discarded += 1
	return discarded

func stage_deck_size():
	return deck.size()
