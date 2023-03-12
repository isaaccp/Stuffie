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
	character.set_id_position(save_state.id_position)
	character.total_action_points = save_state.total_action_points
	character.total_move_points = save_state.total_move_points
	character.total_hit_points = save_state.total_hit_points
	character.cards_per_turn = save_state.cards_per_turn
	character.action_points = save_state.action_points
	character.move_points = save_state.move_points
	character.hit_points = save_state.hit_points
	character.block = save_state.block
	character.power = save_state.power
	character.dodge = save_state.dodge
	character.relic_manager = save_state.relic_manager
	character.deck = save_state.deck
	character.initialize(false)
	return character
