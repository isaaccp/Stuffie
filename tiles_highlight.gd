extends Highlight

class_name TilesHighlight

func _init(map_manager: MapManager, tiles: Array[Vector2i]=[]):
	super(map_manager)

	clear_on_refresh = false
	set_tiles(tiles)

func set_tiles(tiles: Array):
	self.tiles = tiles
	self.labeled_tiles = {}
	refresh()

func set_labeled_tiles(labeled_tiles: Dictionary):
	self.labeled_tiles = labeled_tiles
	self.tiles = []
	refresh()

func _refresh_tiles():
	pass
