extends Relic

class_name AdrenalineRushRelic

func _tooltip():
	return "Gain 1 extra AP on your first turn of each combat"

func _on_start_stage(character: Character):
	character.action_points += 1
