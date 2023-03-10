extends Resource

class_name RunSaveState

@export var state: String
@export var stage_number: int
@export var gold: int
@export var relic_list: RelicList
@export var run_type: GameRun.RunType
@export var characters: Array[CharacterSaveState]
@export var stage_type: GameRun.StageType
@export var stage_name: String
@export var combat_state: CombatSaveState
