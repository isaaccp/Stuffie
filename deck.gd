extends Resource

class_name Deck

@export var cards: Array[Card]
var hand: Array[Card]
var discard: Array[Card]

func shuffle():
	cards.shuffle()
	
func draw_card():
	if cards.is_empty():
		shuffle_discard()
	hand.append(cards.pop_back())
	
func draw_cards(cards: int):
	for i in cards:
		draw_card()

func shuffle_discard():
	while not discard.is_empty():
		cards.append(discard.pop_back())
	shuffle()
	
func discard_card(index: int):
	discard.append(hand.pop_at(index))

func discard_hand():
	while not hand.is_empty():
		discard.append(hand.pop_back())
