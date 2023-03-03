extends Highlight

class_name SingleCursorHighlight

func _init(map_manager: MapManager, pos: Vector2i):
	super(map_manager)

	clear_on_refresh = false
	tiles = [pos]
	refresh()

func update(pos: Vector2i):
	tiles = [pos]
	refresh()

func _refresh_tiles():
	pass
