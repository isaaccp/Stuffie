extends Resource

class_name EventChoice

@export var text: String
# If preview is true, the choice_effects will be displayed.
@export var preview_choice_effects = true
# If preview is true, there should be only one entry in 'effects'.
# The effect will be displayed before making the choice.
@export var preview_resolution_effects = false
@export var hide_if_preconditions_fail = false
@export var preconditions: Array[EventChoicePrecondition]
# Common effects that take place based on the choice.
@export var choice_effects: Array[CardEffect]
# Set of effects to choose from for resolution.
@export var effects: Array[EventChoiceEffect]

func get_preconditions_description():
	var precondition_texts: PackedStringArray = []
	for precondition in preconditions:
		precondition_texts.push_back(precondition.get_description())
	return ', '.join(precondition_texts)

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
