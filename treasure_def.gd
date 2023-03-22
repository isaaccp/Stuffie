extends Resource

class_name TreasureDef

# Changing this to a Card causes some issue due to some cycle
# (likely Card -> Relic -> Character -> Card). Unless we break
# that cycle, we should keep this as CardEffect.
@export var effects: Array[CardEffect]
