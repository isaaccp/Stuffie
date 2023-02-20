extends Relic

class_name EndStageHealRelic

@export var heal_amount: int

func _on_end_stage(character: Character):
	character.heal(heal_amount)
