extends Resource

class_name Hand

var cards: Array[Card]

func clear():
	cards.clear()
	
func add_card(card: Card):
	cards.append(card)
	
func remove_card(index: int):
	cards.remove_at(index)
