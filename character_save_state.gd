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
@export var destroyed: bool
@export var block: int
@export var power: int
@export var dodge: int
@export var relic_manager: RelicManager
@export var deck: Deck
