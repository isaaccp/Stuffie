extends Control

@export var selector: CharacterSelection

func initialize(current_characters: Array):
	var current_character_ids = {}
	var new_characters = []
	for character in current_characters:
		current_character_ids[character.character_type] = true
	for character_id in Enum.CharacterId.values():
		if character_id == Enum.CharacterId.NO_CHARACTER:
			continue
		if character_id not in current_character_ids:
			var character = CharacterLoader.create(character_id)
			new_characters.push_back(character)
	selector.characters = new_characters

func character_selected():
	return selector.character_selected
