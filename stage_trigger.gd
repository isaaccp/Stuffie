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

var trigger_type: TriggerType
var turn: int
var enemies_killed: int
var switch_pos: Vector2i

var effect_type: EffectType
var door_pos: Vector2i
