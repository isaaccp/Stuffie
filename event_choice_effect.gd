extends Resource

class_name EventChoiceEffect

enum TargetType {
	# Affects either all characters or the chosen character if the event required choosing a character.
	CHOSEN_CHARACTER_OR_ALL_CHARACTERS,
	ALL_CHARACTERS,
	RANDOM_CHARACTER,
	CHOOSE_NEW_CHARACTER,
}

# Probability weight (e.g., if choices have weights 2, 1, 1, first one has 50% chance)
@export var target_type: TargetType
@export var probability = 1
@export var effects: Array[CardEffect]
@export_multiline var resolution_text: String
