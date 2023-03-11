extends RefCounted

class_name FieldOfView

var mrpas: MRPAS
var cache: Dictionary
var mutex = Mutex.new()
var tiles_cached = 0
var visible_tiles_cached = 0
const MAX_DISTANCE = 10

func _init(map: MapManager):
	mrpas = MRPAS.new(map.map_rect.size)
	for loc in map.base_view_blocking_locations:
		mrpas.set_transparent(loc, false)
	for loc in map.door_locs:
		if map.door_locs[loc].solid():
			mrpas.set_transparent(loc, false)

func get_fov(pos: Vector2i):
	mutex.lock()
	if not pos in cache:
		mrpas.clear_field_of_view()
		mrpas.compute_field_of_view(pos, MAX_DISTANCE)
		cache[pos] = mrpas.fov_tiles()
		tiles_cached += 1
		visible_tiles_cached += len(cache[pos])
	var result = cache[pos]
	mutex.unlock()
	return result

func set_solid(pos: Vector2i, solid: bool = true):
	var transparent = not solid
	if mrpas.is_transparent(pos) == transparent:
		return
	mutex.lock()
	mrpas.set_transparent(pos, transparent)
	_invalidate()
	mutex.unlock()

func _invalidate():
	# Must be called with mutex held.
	tiles_cached = 0
	visible_tiles_cached = 0
	cache.clear()
