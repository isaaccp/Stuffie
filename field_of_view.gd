extends RefCounted

class_name FieldOfView

var mrpas: MRPAS
# Size of the cache could get very big as it quadratic with number of tiles,
# may need to make it an LRU or similar with max number of entries.
var cache: Dictionary
var mutex = Mutex.new()
var tiles_cached = 0
var visible_tiles_cached = 0
const MAX_DISTANCE = 10

func _init(size: Vector2i, view_blocking_locs: Dictionary, door_locs: Dictionary):
	mrpas = MRPAS.new(size)
	for loc in view_blocking_locs:
		mrpas.set_transparent(loc, false)
	for loc in door_locs:
		if door_locs[loc].solid():
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
