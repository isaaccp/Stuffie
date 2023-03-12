extends WorldEntity

class_name Treasure

# For now we'll choose between these common choices, add rare later.
@export var common: Array[TreasureDef]
var def: TreasureDef
var turns_left = 2

func initialize():
	def = common[randi() % common.size()]

func get_description(character: Character):
	return CardEffect.join_effects_text(character, def.effects)

func get_save_state():
	var state = TreasureSaveState.new()
	state.def = def
	state.turns_left = turns_left
	state.position = get_id_position()
	return state
