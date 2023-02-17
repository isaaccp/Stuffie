extends Highlight

class_name TilesHighlight

func _init(map_manager: MapManager, camera3d: Camera3D, fixed_tiles: Array):
	super(map_manager, camera3d)
	# Do not clear tiles on refresh.
	clear_on_refresh = false
	for tile in fixed_tiles:
		tiles.push_back(tile)

func _refresh_tiles():
	pass
