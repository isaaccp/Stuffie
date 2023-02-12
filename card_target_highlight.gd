extends Highlight

class_name CardTargetHighlight

var id_position: Vector2i
var direction: Vector2
var card_target: Card

func _init(map_manager: MapManager, camera3d: Camera3D, pos: Vector2i, dir: Vector2, card: Card):
	super(map_manager, camera3d)
	id_position = pos
	direction = dir
	card_target = card
	
func update(pos: Vector2i, dir: Vector2):
	id_position = pos
	direction = dir
	refresh()
	
func _refresh_tiles():
	var target_mode = card_target.target_mode
	if target_mode == Card.TargetMode.SELF:
		tiles.push_back(id_position)
	elif target_mode in [Card.TargetMode.ENEMY, Card.TargetMode.AREA]:
		for effect_pos in card_target.effect_area(direction):
			tiles.push_back(id_position + effect_pos)
