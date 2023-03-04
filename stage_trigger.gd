extends Resource

class_name StageTrigger

enum TriggerType {
  BEGIN_TURN,
  END_TURN,
  ENEMIES_KILLED,
  SWITCH,
}

enum EffectType {
  SPAWN_CHEST,
  OPEN_DOOR,
  CLOSE_DOOR,
}

@export var trigger_type: TriggerType
@export var turn: int
@export var enemies_killed: int
@export var switch_pos: Vector2i

@export var effect_type: EffectType
@export var door_pos: Vector2i
