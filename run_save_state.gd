extends Resource

class_name RunSaveState

# In Windows, state is saved in:
# ~/AppData/Roaming/Godot/app_userdata/Stuffie/stuffie_save.tres
@export var state: String
@export var stage_number: int
@export var gold: int
@export var relic_list: RelicList
@export var event_list: EventList
@export var run_type: RunDef.RunType
@export var characters: Array[CharacterSaveState]
@export var stage_type: StageDef.StageType
@export var stage_name: String
@export var combat_state: CombatSaveState
