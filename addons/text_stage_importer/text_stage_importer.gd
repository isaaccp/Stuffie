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
		_add_starting_positions()

	func get_stage():
		return stage

	func _parse_stage_completion():
		print("Parsing stage completion")
		var stage_completion_type = stage.StageCompletionType.get(lines[pline])
		assert(stage_completion_type != null)
		stage.stage_completion_type = stage_completion_type
		pline += 1

	func _parse_enemy_map():
		print("Parsing enemy map")
		while lines[pline] != '-':
			var parts = lines[pline].split(' ')
			assert(parts.size() == 2)
			var letter = parts[0]
			var enemy_id = stage.EnemyId.get(parts[1])
			assert(enemy_id != null)
			enemy_map[letter] = enemy_id
			pline += 1
		# Skip '-'.
		pline += 1

	func _parse_map():
		print("Parsing map")
		map = lines.slice(pline)
		var mesh_lib = preload("res://resources/kaykit-dungeon/kaykit_dungeon.meshlib")
		item_map = _get_mesh_lib_items(mesh_lib)
		gridmap = GridMap.new()
		max_x = 0
		for line in map:
			max_x = max(max_x, line.length())
		max_y = map.size()
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
				if tile == '#':
					var item = _choose_wall_item(x, y)
					_set_gridmap_tile(x, y, 1, item.item, item.orientation)
				elif tile.is_valid_int():
					starting_positions[int(tile)] = Vector2i(x, y)
				elif enemy_map.has(tile):
					var enemy_position = EnemyPosition.new()
					enemy_position.enemy_id = enemy_map[tile]
					enemy_position.position = Vector2i(x, y)
					stage.enemies.push_back(enemy_position)

	func _add_starting_positions():
		for i in range(starting_positions.size()):
			assert(starting_positions.has(i+1))
			stage.starting_positions.push_back(starting_positions[i+1])

	func _orientation(orientation: Vector3):
		var basis = Basis.looking_at(orientation)
		var orthogonal_index = gridmap.get_orthogonal_index_from_basis(basis)
		return orthogonal_index

	func _item(item: Item, orientation=Vector3.FORWARD):
		return ItemOrientation.new(item, _orientation(orientation))

	func _choose_wall_item(x: int, y: int):
		var forward = _get_tile(x, y-1)
		var back = _get_tile(x, y+1)
		var left = _get_tile(x-1, y)
		var right = _get_tile(x+1, y)

		var count = [forward, back, left, right].count('#')
		if count == 4:
			return _item(Item.WALL_CROSS)
		elif count == 3:
			# TODO: Make sure those are right!
			if back != '#':
				return _item(Item.WALL_T, Vector3.RIGHT)
			elif left != '#':
				return _item(Item.WALL_T, Vector3.BACK)
			elif forward != '#':
				return _item(Item.WALL_T, Vector3.LEFT)
			elif right != '#':
				return _item(Item.WALL_T, Vector3.UP)
		elif count == 2:
			if forward == back or left == right:
				if right == '#':
					return _item(Item.WALL, Vector3.FORWARD)
				else:
					return _item(Item.WALL, Vector3.RIGHT)
			else:
				if back == '#':
					if left == '#':
						return _item(Item.WALL_CORNER, Vector3.FORWARD)
					else:
						return _item(Item.WALL_CORNER, Vector3.LEFT)
				elif forward == '#':
					if left == '#':
						return _item(Item.WALL_CORNER, Vector3.RIGHT)
					else:
						return _item(Item.WALL_CORNER, Vector3.BACK)
		else:
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
