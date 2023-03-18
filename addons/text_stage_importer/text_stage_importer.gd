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
		WALL_GATE_DOOR,
		PILLAR,
		BOOKCASE_FILLED,
		BOOKCASE_FILLED_BROKEN,
		BOOKCASE_WIDE_FILLED,
		BOOKCASE_WIDE_FILLED_BROKEN,
		TABLE_MEDIUM,
		TORCH_WALL,
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
		Item.WALL_GATE_DOOR: "wall_gateDoor",
		Item.PILLAR: "pillar",
		Item.BOOKCASE_FILLED: "bookcaseFilled",
		Item.BOOKCASE_FILLED_BROKEN: "bookcaseFilled_broken",
		Item.BOOKCASE_WIDE_FILLED: "bookcaseWideFilled",
		Item.BOOKCASE_WIDE_FILLED_BROKEN: "bookcaseWideFilled_broken",
		Item.TABLE_MEDIUM: "tableMedium",
		Item.TORCH_WALL: "torchWall",
	}

	var obstacles = [
		Item.BOOKCASE_FILLED,
		Item.BOOKCASE_FILLED_BROKEN,
		Item.BOOKCASE_WIDE_FILLED,
		Item.BOOKCASE_WIDE_FILLED_BROKEN,
		Item.TABLE_MEDIUM,
	]

	enum WallItemType {
		WALL,
		CORNER,
		T,
		CROSS,
		DOOR,
	}

	func _make_wall_item_dict(wall, corner, t, cross, door):
		var dict = {}
		if wall:
			dict[WallItemType.WALL] = wall
		if corner:
			dict[WallItemType.CORNER] = corner
		if t:
			dict[WallItemType.T] = t
		if cross:
			dict[WallItemType.CROSS] = cross
		if door:
			dict[WallItemType.DOOR] = door
		return dict

	var wall_items = {
		'#': _make_wall_item_dict(Item.WALL, Item.WALL_CORNER, Item.WALL_T, Item.WALL_CROSS, Item.WALL_DOOR),
		'X': _make_wall_item_dict(Item.WALL_GATE, Item.WALL_GATE_CORNER, Item.WALL_GATE, Item.WALL_GATE, Item.WALL_GATE_DOOR),
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
			var enemy_id = Enum.EnemyId.get(parts[1])
			assert(enemy_id != null)
			assert(parts[2].is_valid_int())
			var level = int(parts[2])
			enemy_map[letter] = [enemy_id, level]
			pline += 1
		# Skip '-'.
		pline += 1

	func _can_place_torch(tile: String):
		if tile in wall_items or tile == '%' or tile == 'x' or tile == ' ':
			return false
		return true

	func _add_torches(x: int, y: int):
		var pos = Vector2i(x, y)
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var new_pos = pos + direction
			var tile = _get_tile(new_pos.x, new_pos.y)
			if not _can_place_torch(tile):
				continue
			var orientation = Vector3(-direction.x, 0, -direction.y)
			_set_gridmap_tile(new_pos.x, new_pos.y, 1, Item.TORCH_WALL, _orientation(orientation))

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
		# This order of iteration matters as this way we go down line by
		# line, which is the order used for doors, etc in triggers.
		for y in range(max_y):
			for x in range(max_x):
				var tile = _get_tile(x, y)
				if tile != ' ':
					_set_gridmap_tile(x, y, 0, Item.GROUND)
				if tile == '#' or tile == '%' or tile == 'X':
					var torch = false
					if tile == '%':
						torch = true
						tile = '#'
					var item = _choose_wall_item(tile, x, y)
					if item != null:
						_set_gridmap_tile(x, y, 1, item.item, item.orientation)
					if torch:
						_add_torches(x, y)
					stage.solid_tiles.push_back(Vector2i(x, y))
					if tile == '#':
						stage.view_blocking_tiles.push_back(Vector2i(x, y))
				elif tile == '+' or tile == '-':
					var item = _choose_door_item(x, y)
					_set_gridmap_tile(x, y, 1, item.item, item.orientation)
					var door_state: Door.DoorState
					if tile == '+':
						door_state = Door.DoorState.CLOSED
					else:
						door_state = Door.DoorState.OPEN
					var wall_type: DoorDef.WallType
					if item.item == Item.WALL_DOOR:
						wall_type = DoorDef.WallType.NORMAL
					else:
						wall_type = DoorDef.WallType.CAGE
					stage.doors.push_back(DoorDef.create(Vector2i(x, y), door_state, wall_type))
				elif tile == 'x':
					# Non-view blocking obstacle.
					var item = _choose_obstacle_item()
					_set_gridmap_tile(x, y, 1, item.item, item.orientation)
					stage.solid_tiles.push_back(Vector2i(x, y))
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
		while pline < lines.size() and lines[pline] != '-':
			var trigger = StageTrigger.new()
			var parts = lines[pline].split(':')
			assert(parts.size() == 2)
			var trigger_parts = parts[0].split(' ')
			var effect_parts = parts[1].split(' ')
			trigger.trigger_type = trigger.TriggerType.get(trigger_parts[0])
			assert(trigger.trigger_type != null)
			match trigger.trigger_type:
				trigger.TriggerType.BEGIN_TURN,trigger.TriggerType.END_TURN:
					assert(trigger_parts.size() == 2)
					assert(trigger_parts[1].is_valid_int())
					trigger.turn = int(trigger_parts[1])
				trigger.TriggerType.ENEMIES_KILLED:
					assert(trigger_parts.size() == 2)
					assert(trigger_parts[1].is_valid_int())
					trigger.enemies_killed = int(trigger_parts[1])
				trigger.TriggerType.SWITCH:
					assert(trigger_parts.size() == 2)
					assert(trigger_parts[1].is_valid_int())
					# trigger.switch_pos = TODO
			trigger.effect_type = trigger.EffectType.get(effect_parts[0])
			assert(trigger.effect_type != null)
			match trigger.effect_type:
				trigger.EffectType.SPAWN_CHEST:
					assert(effect_parts.size() == 1)
				trigger.EffectType.OPEN_DOOR,trigger.EffectType.CLOSE_DOOR:
					assert(effect_parts.size() == 2)
					assert(effect_parts[1].is_valid_int())
					trigger.door_pos = stage.doors[int(effect_parts[1])].pos
			stage.triggers.push_back(trigger)
			pline += 1

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

		var count = 0
		for wall_type in [forward, back, left, right]:
			if wall_type in wall_items.keys():
				count += 1
		if count == 4:
			return _wall_item(tile, WallItemType.CROSS)
		elif count == 3:
			# TODO: Fix those.
			if back != tile:
				return _wall_item(tile, WallItemType.T, Vector3.BACK)
			elif left != tile:
				return _wall_item(tile, WallItemType.T, Vector3.LEFT)
			elif forward != tile:
				return _wall_item(tile, WallItemType.T, Vector3.FORWARD)
			elif right != tile:
				return _wall_item(tile, WallItemType.T, Vector3.RIGHT)
		elif count == 2:
			if forward == back or left == right:
				if right == tile:
					return _wall_item(tile, WallItemType.WALL, Vector3.FORWARD)
				else:
					return _wall_item(tile, WallItemType.WALL, Vector3.LEFT)
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
		elif count == 1:
			return null
		else:
			# TODO: Make this different depending on # or X?
			return _item(Item.PILLAR)

	func _choose_door_item(x: int, y: int):
		var forward = _get_tile(x, y-1)
		var back = _get_tile(x, y+1)
		var left = _get_tile(x-1, y)
		var right = _get_tile(x+1, y)

		var wall_item_count = 0
		var wall_item = ''
		for tile in [forward, back, left, right]:
			if tile in wall_items.keys():
				if wall_item == '':
					wall_item = tile
				else:
					# All tiles surrounding a door should be of same wall type.
					assert(wall_item, tile)
				wall_item_count += 1
		# A door should be surrounded by exactly two walls.
		assert(wall_item_count == 2)
		if right == wall_item:
			return _wall_item(wall_item, WallItemType.DOOR, Vector3.FORWARD)
		else:
			return _wall_item(wall_item, WallItemType.DOOR, Vector3.LEFT)

	func _choose_obstacle_item():
		# Random item and random orientation.
		var item = obstacles[randi() % obstacles.size()]
		var orientation = [Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT, Vector3.LEFT][randi() % 4]
		return _item(item, orientation)

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
