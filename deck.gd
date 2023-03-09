extends Resource

class_name Deck

# Set of cards in the deck.
@export var cards: Array[Card]
# Current cards in deck during stage.
@export var deck: Array[Card]
# Current cards in hand during stage.
@export var hand: Array[Card]
# Current cards in discard pile during stage.
@export var discard: Array[Card]

func reset():
	deck.clear()
	hand.clear()
	discard.clear()
	for card in cards:
		deck.push_back(card.duplicate(true))
	shuffle()

func add_card(card: Card):
	cards.push_back(card)

func shuffle():
	deck.shuffle()

# Returns "first" card in the deck that matches a condition.
# End of deck array is top of deck.
func find_card(condition: Callable) -> int:
	for i in range(deck.size()-1, -1, -1):
		if condition.call(deck[i]):
			return i
	return -1

# Returns true if succesful.
func draw_card_condition(condition: Callable) -> int:
	var card_index = find_card(condition)
	if card_index == -1:
		shuffle_discard()
		# If still can't find card, give up.
		card_index = find_card(condition)
		if card_index == -1:
			return false
	var card = deck[card_index]
	deck.remove_at(card_index)
	hand.append(card)
	return true

func draw_cards(num_cards: int, condition: Callable = func(c): return true):
	for i in num_cards:
		var drawn = draw_card_condition(condition)
		if not drawn:
			return i
	return num_cards

func draw_attacks(num_cards: int):
	return draw_cards(num_cards, func(c): return c.is_attack())

func num_hand_cards():
	return hand.size()

func shuffle_discard():
	while not discard.is_empty():
		deck.append(discard.pop_back())
	shuffle()

func discard_card(index: int):
	discard.append(hand.pop_at(index))

func exhaust_card(index: int):
	hand.remove_at(index)

func discard_hand():
	var discarded = 0
	while not hand.is_empty():
		discard.append(hand.pop_back())
		discarded += 1
	return discarded

func stage_deck_size():
	return deck.size()
