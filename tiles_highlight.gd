extends Highlight

class_name TilesHighlight

func _init(map_manager: MapManager, fixed_tiles: Array):
	super(map_manager)

	clear_on_refresh = false
	for tile in fixed_tiles:
		tiles.push_back(tile)

func _refresh_tiles():
	pass
