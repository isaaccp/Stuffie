extends Resource

class_name CharacterSaveState

@export var character_type: Enum.CharacterId
@export var id_position: Vector2i
@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
@export var cards_per_turn: int
@export var action_points: int
@export var move_points: int
@export var hit_points: int
@export var is_destroyed: bool
@export var relic_manager: RelicManager
@export var status_manager: StatusManager
@export var deck: Deck
