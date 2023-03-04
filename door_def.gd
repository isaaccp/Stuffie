extends Resource

class_name DoorDef

@export var pos: Vector2i
@export var state: Door.DoorState

static func create(pos: Vector2i, state: Door.DoorState):
	var def = DoorDef.new()
	def.pos = pos
	def.state = state
	return def
