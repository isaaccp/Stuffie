extends WorldEntity

class_name Treasure

# For now we'll choose between these common choices, add rare later.
@export var common: Array[TreasureDef]
var def: TreasureDef
var turns_left = 2

func _ready():
	def = common[randi() % common.size()]

func get_description():
	return CardEffectNew.join_effects_text(def.effects)
