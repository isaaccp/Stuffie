extends Resource

class_name TorchDef

@export var pos: Vector2i
@export var orientation: Vector2i

static func create(pos: Vector2i, orientation: Vector2i):
	var def = TorchDef.new()
	def.pos = pos
	def.orientation = orientation
	return def
