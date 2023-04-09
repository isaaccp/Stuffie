extends Resource

class_name EventChoice

@export var text: String
@export var effects: Array[EventChoiceEffect]

# Return a random effect based on the proportional weights.
func get_effect() -> EventChoiceEffect:
	var sum = 0
	var thresholds = []
	for effect in effects:
		sum += effect.probability
		thresholds.push_back(sum)
	var rand = randi() % sum
	for i in thresholds.size():
		if rand < thresholds[i]:
			return effects[i]
	assert(false)
	return effects[0]
