extends Resource

class_name DoorDef

enum WallType {
	NORMAL,
	CAGE,
}

@export var pos: Vector2i
@export var state: Door.DoorState
@export var wall_type: WallType

static func create(pos: Vector2i, state: Door.DoorState, wall_type: WallType):
	var def = DoorDef.new()
	def.pos = pos
	def.state = state
	def.wall_type = wall_type
	return def
