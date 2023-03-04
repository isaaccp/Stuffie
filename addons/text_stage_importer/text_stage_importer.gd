@tool
extends EditorImportPlugin

func _get_importer_name():
	return "text_stage_importer"

func _get_visible_name():
	return "Text Stage"

func _get_recognized_extensions():
	return ["stage"]

func _get_save_extension():
	return "tscn"

func _get_priority():
	return 1

func _get_resource_type():
	return "PackedScene"

func _get_preset_count():
	return 1

func _get_preset_name(i):
	return "Default"

func _get_import_options(path, i):
	return []
	# return [{"name": "my_option", "default_value": false}]

class StageLoader:
	var lines: Array
	var map: Array
	var max_x: int
	var max_y: int
	const CELL_SIZE = Vector3(2, 1, 2)

	var stage: Stage
	var gridmap: GridMap
	var starting_positions = {}

	# Current parsing line.
	var pline = 0

	enum Item {
		GROUND,
		WALL,
		WALL_CORNER,
		WALL_T,
		WALL_CROSS,
		WALL_DOOR,
		WALL_GATE,
		WALL_GATE_CORNER,
		PILLAR,
	}

	var item_mesh_map = {
		Item.GROUND: "tileBrickB_small",
		Item.WALL: "wall",
		Item.WALL_CORNER: "wallCorner",
		Item.WALL_T: "wallSplit",
		Item.WALL_CROSS: "wallIntersection",
		Item.WALL_DOOR: "wall_door",
		Item.WALL_GATE: "wall_gate",
		Item.WALL_GATE_CORNER: "wall_gateCorner",
		Item.PILLAR: "pillar",
	}

	enum WallItemType {
		WALL,
		CORNER,
		T,
		CROSS,
	}

	func _make_wall_item_dict(wall, corner, t, cross):
		var dict = {}
		if wall:
			dict[WallItemType.WALL] = wall
		if corner:
			dict[WallItemType.CORNER] = corner
		if t:
			dict[WallItemType.T] = t
		if cross:
			dict[WallItemType.CROSS] = cross
		return dict

	var wall_items = {
		'#': _make_wall_item_dict(Item.WALL, Item.WALL_CORNER, Item.WALL_T, Item.WALL_CROSS),
		'X': _make_wall_item_dict(Item.WALL_GATE, Item.WALL_GATE_CORNER, null, null),
	}

	var enemy_map = {}

	var item_map: Dictionary


	class ItemOrientation:
		var item: Item
		var orientation: int

		func _init(item: Item, orientation:int ):
			self.item = item
			self.orientation = orientation

	func _init(content: String):
		lines = content.split("\n", false)
		stage = Stage.new()
		_parse_stage_completion()
		_parse_enemy_map()
		_parse_map()
		_parse_triggers()
		_add_starting_positions()

	func get_stage():
		return stage

	func _parse_stage_completion():
		print("Parsing stage completion")
		var parts = lines[pline].split(' ')
		var stage_completion_type = stage.StageCompletionType.get(parts[0])
		assert(stage_completion_type != null)
		stage.stage_completion_type = stage_completion_type
		match stage_completion_type:
			stage.StageCompletionType.KILL_ALL_ENEMIES:
				assert(parts.size() == 1)
			stage.StageCompletionType.KILL_N_ENEMIES:
				assert(parts.size() == 2)
				assert(parts[1].is_valid_int())
				stage.kill_n_enemies_target = int(parts[1])
			stage.StageCompletionType.SURVIVE_N_TURNS:
				assert(parts.size() == 2)
				assert(parts[1].is_valid_int())
				stage.survive_n_turns_target = int(parts[1])
		pline += 1

	func _parse_enemy_map():
		print("Parsing enemy map")
		while lines[pline] != '-':
			var parts = lines[pline].split(' ')
			assert(parts.size() == 3)
			var letter = parts[0]
			assert(letter.length() == 1)
			var enemy_id = stage.EnemyId.get(parts[1])
			assert(enemy_id != null)
			assert(parts[2].is_valid_int())
			var level = int(parts[2])
			enemy_map[letter] = [enemy_id, level]
			pline += 1
		# Skip '-'.
		pline += 1

	func _parse_map():
		print("Parsing map")
		map = []
		while pline < lines.size() and lines[pline] != '-':
			map.push_back(lines[pline])
			pline += 1
		# Skip '-' if present.
		pline += 1
		var mesh_lib = preload("res://resources/kaykit-dungeon/kaykit_dungeon.meshlib")
		item_map = _get_mesh_lib_items(mesh_lib)
		gridmap = GridMap.new()
		max_x = 0
		for line in map:
			max_x = max(max_x, line.length())
		max_y = map.size()
		stage.rect = Rect2i(Vector2i(0, 0), Vector2i(max_x, max_y))
		stage.name = "Stage"
		gridmap.name = "GridMap"
		stage.add_child(gridmap)
		gridmap.owner = stage
		gridmap.mesh_library = mesh_lib
		gridmap.cell_size = CELL_SIZE
		for x in range(max_x):
			for y in range(max_y):
				var tile = _get_tile(x, y)
				if tile != ' ':
					_set_gridmap_tile(x, y, 0, Item.GROUND)
				if tile == '#' or tile == 'X':
					var item = _choose_wall_item(tile, x, y)
					_set_gridmap_tile(x, y, 1, item.item, item.orientation)
					stage.solid_tiles.push_back(Vector2i(x, y))
					if tile == '#':
						stage.view_blocking_tiles.push_back(Vector2i(x, y))
				elif tile.is_valid_int():
					starting_positions[int(tile)] = Vector2i(x, y)
				elif enemy_map.has(tile):
					var enemy_position = EnemyPosition.new()
					var enemy_info = enemy_map[tile]
					enemy_position.enemy_id = enemy_info[0]
					enemy_position.level = enemy_info[1]
					enemy_position.position = Vector2i(x, y)
					stage.enemies.push_back(enemy_position)
				elif tile == '@':
					assert(stage.stage_completion_type == stage.StageCompletionType.REACH_POSITION)
					stage.reach_position_target = Vector2i(x, y)

	func _parse_triggers():
		print("Parsing triggers")
		# Add default triggers unless 'SKIP_DEFAULT_TRIGGERS' is specified.
		if pline >= lines.size():
			_add_default_triggers()
		else:
			if lines[pline] == 'SKIP_DEFAULT_TRIGGERS':
				pline += 1
			else:
				_add_default_triggers()
		# TODO: Parse more triggers.

	func _add_default_triggers():
		var trigger = StageTrigger.new()
		trigger.trigger_type = StageTrigger.TriggerType.BEGIN_TURN
		trigger.turn = 2
		trigger.effect_type = StageTrigger.EffectType.SPAWN_CHEST
		stage.triggers.push_back(trigger)

	func _add_starting_positions():
		assert(starting_positions.size() > 0)
		for i in range(starting_positions.size()):
			assert(starting_positions.has(i+1))
			stage.starting_positions.push_back(starting_positions[i+1])

	func _orientation(orientation: Vector3):
		var basis = Basis.looking_at(orientation)
		var orthogonal_index = gridmap.get_orthogonal_index_from_basis(basis)
		return orthogonal_index

	func _item(item: Item, orientation=Vector3.FORWARD):
		return ItemOrientation.new(item, _orientation(orientation))

	func _wall_item(tile: String, type: WallItemType, orientation=Vector3.FORWARD):
		assert(wall_items.has(tile))
		var tile_wall_items = wall_items[tile]
		assert(tile_wall_items.has(type))
		var item = tile_wall_items[type]
		return _item(item, orientation)

	func _choose_wall_item(tile: String, x: int, y: int):
		var forward = _get_tile(x, y-1)
		var back = _get_tile(x, y+1)
		var left = _get_tile(x-1, y)
		var right = _get_tile(x+1, y)

		var count = [forward, back, left, right].count(tile)
		if count == 4:
			return _wall_item(tile, WallItemType.CROSS)
		elif count == 3:
			# TODO: Fix those.
			if back != tile:
				return _wall_item(tile, WallItemType.T, Vector3.RIGHT)
			elif left != tile:
				return _wall_item(tile, WallItemType.T, Vector3.BACK)
			elif forward != tile:
				return _wall_item(tile, WallItemType.T, Vector3.LEFT)
			elif right != tile:
				return _wall_item(tile, WallItemType.T, Vector3.UP)
		elif count == 2:
			if forward == back or left == right:
				if right == tile:
					return _wall_item(tile, WallItemType.WALL, Vector3.FORWARD)
				else:
					return _wall_item(tile, WallItemType.WALL, Vector3.RIGHT)
			else:
				if back == tile:
					if left == tile:
						return _wall_item(tile, WallItemType.CORNER, Vector3.FORWARD)
					else:
						return _wall_item(tile, WallItemType.CORNER, Vector3.LEFT)
				elif forward == tile:
					if left == tile:
						return _wall_item(tile, WallItemType.CORNER, Vector3.RIGHT)
					else:
						return _wall_item(tile, WallItemType.CORNER, Vector3.BACK)
		else:
			# TODO: Make this different depending on # or X?
			return _item(Item.PILLAR)

	func _set_gridmap_tile(x: int, y: int, floor: int, item: Item, orientation=0):
		var item_id = item_map[item]
		gridmap.set_cell_item(Vector3(x, floor, y), item_id, orientation)

	func _get_mesh_lib_items(mesh_lib: MeshLibrary):
		var items = {}
		for item in item_mesh_map.keys():
			var item_id = mesh_lib.find_item_by_name(item_mesh_map[item])
			items[item] = item_id
		return items

	func _get_tile(x: int, y: int):
		if x < 0 or x >= max_x:
			return ' '
		if y < 0 or y >= max_y:
			return ' '
		var line = map[y]
		if x >= line.length():
			return ' '
		return line[x]

func _import_stage(content: String) -> PackedScene:
	var loader = StageLoader.new(content)
	var stage = loader.get_stage()
	var packed_scene = PackedScene.new()
	packed_scene.pack(stage)
	return packed_scene

func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED
	print("Importing ", source_file)
	var scene = _import_stage(file.get_as_text())

	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(scene, filename)
