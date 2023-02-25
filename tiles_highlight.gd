extends Highlight

class_name TilesHighlight

func _init(map_manager: MapManager, fixed_tiles: Array):
	super(map_manager)

	clear_on_refresh = false
	set_tiles(fixed_tiles)

func set_tiles(fixed_tiles: Array):
	tiles.clear()
	for tile in fixed_tiles:
		tiles.push_back(tile)
	refresh()

func _refresh_tiles():
	pass
