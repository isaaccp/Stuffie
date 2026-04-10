extends Relic

class_name SpellbookRelic

func _tooltip():
	return "Draw 1 extra card at the start of each turn"

func _on_start_turn(character: Character):
	character.draw_cards(1, null)
