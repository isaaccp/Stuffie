extends Resource

class_name CombatSaveState

@export var turn_number: int
@export var enemies: Array[EnemySaveState]
@export var treasures: Array[TreasureSaveState]
# TODO: Need to record doors and treasures into state.
