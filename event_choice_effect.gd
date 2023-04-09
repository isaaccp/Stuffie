extends Resource

class_name EventChoiceEffect

# Probability weight (e.g., if choices have weights 2, 1, 1, first one has 50% chance)
@export var probability = 1
@export var effects: Array[CardEffect]
@export_multiline var resolution_text: String
