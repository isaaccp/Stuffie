extends WorldEntity

class_name Treasure

# Change this to load treasures at random.

@export var def: TreasureDef
var turns_left = 2

func get_description():
	return CardEffectNew.join_effects_text(def.effects)
