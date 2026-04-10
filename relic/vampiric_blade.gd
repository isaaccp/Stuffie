extends Relic

class_name VampiricBladeRelic

func _tooltip():
	return "Heal 2 HP for each enemy killed"

func _on_stats_added(character: Character, field: Stats.Field, value: int):
	if field == Stats.Field.ENEMIES_KILLED:
		character.heal(2 * value)
