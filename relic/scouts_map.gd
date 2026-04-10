extends Relic

class_name ScoutsMapRelic

func _tooltip():
	return "Gain 4 extra MP at the start of each combat"

func _on_start_stage(character: Character):
	character.move_points += 4
