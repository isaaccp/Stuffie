extends RefCounted

class_name CharacterLoader

const character_scenes = {
	Enum.CharacterId.WARRIOR: preload("res://warrior.tscn"),
	Enum.CharacterId.WIZARD: preload("res://wizard.tscn"),
}

static func create(character_id: Enum.CharacterId) -> Character:
	return character_scenes[character_id].instantiate() as Character

static func restore(save_state: CharacterSaveState) -> Character:
	var character = CharacterLoader.create(save_state.character_type)
	character.load_save_state(save_state)
	return character
