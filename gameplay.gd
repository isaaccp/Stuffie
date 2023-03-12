extends Node3D

class_name Gameplay

enum GameState {
  HUMAN_TURN,
  CPU_TURN,
}

var state_text = {
	GameState.HUMAN_TURN: "Your turn",
	GameState.CPU_TURN: "Enemy turn",
}

enum HumanTurnState {
	# When turn starts. So we can differentiate beginning of turn transitions
	# to WAITING.
	STARTING,
	# Waiting for move or action to be chosen.
	# During this move we show move paths based on mouse pointer.
	WAITING,
	# Executing a move. No actions can be chosen, no character change, etc
	MOVING,
	# An action has been chosen and we are waiting to choose a target.
	ACTION_TARGET,
	# Playing a card. No actions can be chosen, no character change, etc.
	PLAYING_CARD,
	# Teleporting as part of playing a card.
	PLAY_TELEPORTING,
}

var turn_number = 0
var portrait_scene = preload("res://character_portrait.tscn")
var card_ui_scene = preload("res://card_ui.tscn")
var treasure_scene = preload("res://treasure.tscn")

var active_character: Character
var active_character_index: int
# Direction of mouse position respect active character.
# E.g. Vector2.right if it's more to the right than up/down.
var direction: Vector2
var state: GameState
var human_turn_state = HumanTurnState.STARTING
var map_manager = MapManager.new()
var current_path: PackedVector2Array = PackedVector2Array()
var valid_path: bool = false
var too_long_path: bool = false
# Whether the current tile is a valid target (in ACTION_TARGET mode).
var valid_target: bool = false
var tile_map_pos: Vector2i = Vector2i(0, 0)

var current_card_index: int = -1
var current_card: Card
var target_cursor: CardTargetHighlight
var single_cursor: SingleCursorHighlight
var target_area: AreaDistanceHighlight
var player_move_area: TilesHighlight
var enemy_move_area: TilesHighlight
var enemy_attack_area: TilesHighlight
var objective_highlight: TilesHighlight

var camera_panning_speed = 15
var camera_rotation_speed = 100

# Move somewhere where it can be used from anywhere or figure out how to pass.
var tile_size: int = 2
var half_tile2 = Vector2(tile_size/2, tile_size/2)
var half_tile3 = Vector3(tile_size/2, 0, tile_size/2)
var enemy_moving = false
var enemy_turn_manager = EnemyTurnManager.new()
var animation_manager = AnimationManager.new()
var stage_trigger_manager: StageTriggerManager

# New stages are added to this world.
@export var world: Node
# Effects go under this node.
@export var effects: Node
# Enemies are under this node.
@export var enemies_node: Node
@export var doors_node: Node
@export var hand_ui: Control
@export var deck_ui: Control
@export var discard_ui: Control
@export var character_state_ui: Control
@export var camera: Camera3D
@export var camera_pivot: Node3D
@export var end_turn_button: Button
@export var undo_button: Button
@export var treasures: Node
@export var stage_info: Label
@export var objective_info: Label
@export var turn_state_info: Label
@export var enemy_info: RichTextLabel
@export var treasure_info: RichTextLabel
@export var shared_bag_gold_ui: SharedBagGoldUI
@export var move_path: Line2D

class UndoState:
	var position
	var move_points

var undo_states: Dictionary
var party: Node
var shared_bag: SharedBag
var teleport_distance: int
signal teleport_finished

var enemy_walkable_cache: Dictionary
var enemy_attackable_cache: Dictionary
var restored_from_save = false

signal enemy_died
signal character_moved(pos: Vector2i)
signal all_enemies_died
signal new_turn_started(turn: int)

signal stage_done
signal game_over

# Called when the node enters the scene tree for the first time.
func _ready():
	undo_button.hide()

func initialize(stage: Stage, character_party: Node, shared_bag: SharedBag, combat_state: CombatSaveState = null):
	self.shared_bag = shared_bag
	shared_bag_gold_ui.set_shared_bag(shared_bag)
	party = character_party
	var i = 0
	for character in party.get_children():
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		# Add portraits in UI.
		character_state_ui.add_child(character_portrait)
		# Set portrait on character so it can update when e.g. move points change
		character_portrait.set_character(character)
		# Hook character selection.
		character_portrait.portrait.pressed.connect(_on_character_portrait_pressed.bind(i))
		i += 1
	initialize_stage(stage, combat_state)

func initialize_stage(stage: Stage, combat_state: CombatSaveState):
	if combat_state == null:
		stage.initialize(enemies_node)
		var i = 0
		for character in party.get_children():
			character.begin_stage(self)
			character.set_id_position(stage.starting_positions[i])
			i += 1
		# Usually "turn stats" are created at beginning of enemy turn, create here the first time.
		StatsManager.add_level(StatsManager.Level.TURN)
		turn_number = 0
	else:
		for enemy_data in combat_state.enemies:
			var enemy = Enemy.restore(enemy_data)
			enemies_node.add_child(enemy)
			# To show healthbar if they are hurt.
			enemy.refresh()
		turn_number = combat_state.turn_number
		restored_from_save = true
	connect("enemy_died", stage.enemy_died_handler)
	connect("character_moved", stage.character_moved_handler)
	connect("all_enemies_died", stage.all_enemies_died_handler)
	connect("new_turn_started", stage.new_turn_started_handler)
	stage.connect("stage_completed", next_stage)
	stage_trigger_manager = StageTriggerManager.new(stage.triggers)
	stage_trigger_manager.connect_signals(self)
	world.add_child(stage)
	# As of now, some bits of the game require active_character to be set,
	# so set it now before changing state.
	set_active_character(0)
	initialize_map_manager(stage)
	if combat_state != null:
		for treasure_state in combat_state.treasures:
			var treasure = Treasure.restore(treasure_state)
			map_manager.add_treasure(treasure)
			treasures.add_child(treasure)
	enemy_turn_manager.initialize(map_manager)
	enemy_turn_manager.character_died.connect(handle_character_death)
	enemy_turn_manager.invalidated.connect(on_enemy_turn_invalidated)
	enemy_turn_manager.calculated.connect(on_enemy_turn_calculated)
	player_move_area = TilesHighlight.new(map_manager)
	enemy_move_area = TilesHighlight.new(map_manager)
	enemy_attack_area = TilesHighlight.new(map_manager)
	enemy_move_area.set_color(Color(1, 0, 0, 1))
	enemy_attack_area.set_color(Color(1, 1, 1, 1))
	world.add_child(player_move_area)
	world.add_child(enemy_move_area)
	world.add_child(enemy_attack_area)
	if stage.stage_completion_type == stage.StageCompletionType.REACH_POSITION:
		objective_highlight = TilesHighlight.new(map_manager, [stage.reach_position_target])
		objective_highlight.set_color(Color(0, 0, 1, 1))
		objective_highlight.set_width(4)
		objective_highlight.refresh.call_deferred()
		stage.add_child(objective_highlight)
	stage_info.text = "Stage"
	objective_info.text = stage.get_objective_string()
	change_state(GameState.HUMAN_TURN)

func on_enemy_turn_calculated(damage_taken: Array):
	for info in damage_taken:
		var loc = info[0]
		var damage = info[1]
		map_manager.character_locs[loc].set_pending_damage(damage)

func on_enemy_turn_invalidated():
	for character in party.get_children():
		character.clear_pending_damage()

func next_stage():
	StatsManager.remove_level(StatsManager.Level.TURN)
	# Restore AP, MP, remove block/power, etc so it doesn't appear in non-combat
	# stages.
	for character in party.get_children():
		character.end_stage_restore()
	stage_done.emit()

func initialize_map_manager(stage: Stage):
	map_manager.initialize(stage, doors_node)
	map_manager.set_party(party.get_children())
	map_manager.set_enemies(enemies_node.get_children())
	map_manager.initialize_a_star()

func open_door(pos: Vector2i):
	map_manager.open_door(pos)

func close_door(pos: Vector2i):
	map_manager.close_door(pos)

func _on_character_portrait_pressed(index: int):
	# Only allow to change active character during human turn on waiting state.
	if state != GameState.HUMAN_TURN or human_turn_state != HumanTurnState.WAITING:
		return
	set_active_character(index)

func draw_hand():
	# Clear hand.
	for child in hand_ui.get_children():
		child.queue_free()
	for j in active_character.deck.hand.size():
		var card = active_character.deck.hand[j]
		var new_card = card_ui_scene.instantiate() as CardUI
		new_card.initialize(card, active_character, _on_card_pressed.bind(j))
		hand_ui.add_child(new_card)
	# Clear discard.
	for child in discard_ui.get_children():
		child.queue_free()
	# Display last discarded card.
	if not active_character.deck.discard.is_empty():
		var new_card = card_ui_scene.instantiate() as CardUI
		new_card.initialize(active_character.deck.discard.back(), active_character, Callable())
		discard_ui.add_child(new_card)
		new_card.tooltip_text = "%d cards on discard pile" % active_character.deck.discard.size()
	# Set deck tooltip.
	deck_ui.tooltip_text = "%d cards on deck" % active_character.deck.stage_deck_size()

func set_active_character(index: int):
	if index >= party.get_child_count():
		index -= party.get_child_count()

	var i = 0

	for character in party.get_children():
		if i == index:
			active_character = party.get_child(i)
			active_character.set_active(true)
			draw_hand()
		else:
			character.set_active(false)
			character.clear_pending_move_cost()
		i += 1
	active_character_index = index

func _on_card_pressed(index: int):
	if state != GameState.HUMAN_TURN:
		return
	if human_turn_state not in [HumanTurnState.WAITING, HumanTurnState.ACTION_TARGET]:
		return

	if current_card_index != -1:
		hand_ui.get_child(current_card_index).set_highlight(false)
		target_area.queue_free()
		target_cursor.queue_free()
		active_character.clear_pending_action_cost()

	var card = active_character.deck.hand[index]
	if card.cost <= active_character.action_points:
		hand_ui.get_child(index).set_highlight(true)
		current_card_index = index
		current_card = card
		# Update prospective cost in character.
		active_character.set_pending_action_cost(current_card.cost)
		change_human_turn_state(HumanTurnState.ACTION_TARGET)
	else:
		# Not enough action points to play card, throw back to WAITING state.
		change_human_turn_state(HumanTurnState.WAITING)

func create_cursor(pos: Vector2i, direction: Vector2):
	var cursor_pos = pos
	if current_card.target_mode == Card.TargetMode.SELF:
		cursor_pos = active_character.get_id_position()
	target_cursor = CardTargetHighlight.new(map_manager, cursor_pos, direction, current_card)
	target_cursor.set_width(3)
	target_cursor.refresh()
	world.add_child(target_cursor)

func create_single_cursor(pos: Vector2i):
	single_cursor = SingleCursorHighlight.new(map_manager, pos)
	single_cursor.set_width(3)
	single_cursor.refresh()
	world.add_child(single_cursor)

func add_unprojected_point(line: Line2D, world_pos: Vector3):
	var unprojected = camera.unproject_position(world_pos)
	line.add_point(unprojected)

func create_target_area(pos: Vector2i, distance: int):
	# TODO: Optionally (parameter) respect line-of-sight here.
	if is_instance_valid(target_area):
			target_area.queue_free()
	target_area = AreaDistanceHighlight.new(map_manager, pos, distance, true)
	target_area.refresh()
	world.add_child(target_area)

func offsets_within_distance(distance: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var zero = Vector2i(0, 0)
	var i = -distance
	while i <= distance:
		var j = -distance
		while j <= distance:
			var tile = Vector2i(i, j)
			if map_manager.distance(zero, tile) <= distance:
				tiles.push_back(tile)
			j += 1
		i += 1
	return tiles

func get_attack_cells(enemy: Enemy, positions: Array) -> Array:
	var attack_positions: Dictionary
	var offsets = offsets_within_distance(enemy.attack_range())
	for pos in positions:
		var visible_tiles = map_manager.fov.get_fov(pos)
		for offset in offsets:
			var tile = pos + offset
			if map_manager.in_bounds(tile) and not map_manager.is_solid(tile, false, false, false) and tile in visible_tiles:
				attack_positions[tile] = true
	return attack_positions.keys()

func update_move_area(move_positions: Array, attack_positions: Array):
	enemy_move_area.set_tiles(move_positions)
	enemy_move_area.visible = true
	enemy_attack_area.set_tiles(attack_positions)
	enemy_attack_area.visible = true

func path_cost(path: PackedVector2Array) -> int:
	var cost = 0
	for i in path.size()-1:
		var path_diff = path[i+1] - path[i]
		if path_diff[0] == 0 or path_diff[1] == 0:
			cost += 2
		else:
			cost += 3
	return cost

func clear_path():
	current_path.clear()
	move_path.clear_points()
	player_move_area.hide()

func calculate_path(tile_map_pos):
	# Active character position
	var pos = active_character.get_id_position()
	# Calculate mouse pointer position on the tilemap
	current_path = map_manager.get_path(pos, tile_map_pos)
	valid_path = !current_path.is_empty()
	var cost = path_cost(current_path)
	too_long_path = (cost > active_character.move_points)
	# Update prospective cost in character.
	if !valid_path or too_long_path:
		active_character.clear_pending_move_cost()
	else:
		active_character.set_pending_move_cost(cost)
	# Draw path.
	move_path.clear_points()
	if valid_path:
		for point in current_path:
			var location = map_manager.get_world_position(point)
			add_unprojected_point(move_path, location)
		if too_long_path:
			move_path.default_color = Color(1, 0, 0, 1)
			player_move_area.hide()
		else:
			move_path.default_color = Color(1, 1, 1, 1)
			var walkable_cells = map_manager.get_walkable_cells(tile_map_pos, active_character.move_points - cost, [active_character.get_id_position()])
			player_move_area.set_tiles(walkable_cells)
			player_move_area.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == GameState.HUMAN_TURN:
		var camera_move = delta * camera_panning_speed
		var camera_rotate = delta * camera_rotation_speed
		var camera_forward = -camera_pivot.transform.basis.z
		camera_forward.y = 0
		var forward = camera_forward.normalized() * camera_move
		var camera_modified = false
		if Input.is_action_pressed("ui_right"):
			camera_pivot.position += forward.cross(Vector3.UP)
			camera_modified = true
		if Input.is_action_pressed("ui_left"):
			camera_pivot.position -= forward.cross(Vector3.UP)
			camera_modified = true
		if Input.is_action_pressed("ui_up"):
			camera_pivot.position += forward
			camera_modified = true
		if Input.is_action_pressed("ui_down"):
			camera_pivot.position -= forward
			camera_modified = true
		if Input.is_action_pressed("ui_rotate_left"):
			camera_pivot.rotate_y(-camera_rotate*delta)
			camera_modified = true
		if Input.is_action_pressed("ui_rotate_right"):
			camera_pivot.rotate_y(camera_rotate*delta)
			camera_modified = true
		if Input.is_action_just_released("ui_zoom_in"):
			# Prevent from zooming through stage.
			var adjusted_position = camera_pivot.position - forward.cross(Vector3.RIGHT) * 5
			# Yay magic number.
			if adjusted_position.y > -10:
				camera_pivot.position = adjusted_position
		if Input.is_action_just_released("ui_zoom_out"):
			camera_pivot.position += forward.cross(Vector3.RIGHT) * 5
		if camera_modified:
			update_position_direction(get_viewport().get_mouse_position())
	elif state == GameState.CPU_TURN:
		if enemy_turn_manager.fresh and not enemy_moving:
			# Consider adding a CpuTurnState if needed.
			enemy_moving = true
			await enemy_turn_manager.execute_moves(map_manager)
			enemy_moving = false
			change_state(GameState.HUMAN_TURN)

func reset_undo():
	undo_button.hide()
	for character in party.get_children():
		var undo_state = UndoState.new()
		undo_state.position = character.get_id_position()
		undo_state.move_points = character.move_points
		undo_states[character] = undo_state

func apply_undo():
	for character in undo_states:
		var undo_state = undo_states[character]
		map_manager.move_character(character.get_id_position(), undo_state.position)
		character.set_id_position(undo_state.position)
		var reverted_move_points = undo_state.move_points - character.move_points
		character.move_points = undo_state.move_points
		StatsManager.remove(character, Stats.Field.MP_USED, reverted_move_points)
	# No need to reset as it should now match.
	undo_button.hide()
	enemy_turn_manager.update()

func begin_turn():
	for enemy in enemies_node.get_children():
		enemy.end_turn()
	clear_enemy_info_cache()
	turn_number += 1
	for character in party.get_children():
		character.begin_turn()
	reset_undo()
	draw_hand()
	for treasure in treasures.get_children():
		treasure.turns_left -= 1
		if treasure.turns_left == 0:
			var pos = treasure.get_id_position()
			map_manager.remove_treasure(pos)
	new_turn_started.emit(turn_number)
	# To trigger beginning of turn effects.
	change_human_turn_state(HumanTurnState.STARTING)
	change_human_turn_state(HumanTurnState.WAITING)

func spawn_treasure():
	var treasure = treasure_scene.instantiate() as Treasure
	treasure.initialize()
	treasure.set_id_position(map_manager.get_random_empty_tile())
	map_manager.add_treasure(treasure)
	treasures.add_child(treasure)

func change_state(new_state):
	state = new_state
	if state == GameState.HUMAN_TURN:
		# If restored_from_save, don't trigger begin_turn on first human turn.
		if restored_from_save:
			# Need to go through STARTING to trigger enemy updater.
			change_human_turn_state(HumanTurnState.STARTING)
			change_human_turn_state(HumanTurnState.WAITING)
			restored_from_save = false
		else:
			begin_turn()
	elif state == GameState.CPU_TURN:
		StatsManager.turn_stats.print()
		# Re-start turn stats so we can use enemy turn stats in cards next run.
		StatsManager.remove_level(StatsManager.Level.TURN)
		StatsManager.add_level(StatsManager.Level.TURN)
		for character in party.get_children():
			character.end_turn()
	turn_state_info.text = "%s: %d" % [state_text[state], turn_number]

func change_human_turn_state(new_state):
	if new_state == HumanTurnState.WAITING:
		end_turn_button.disabled = false
		if human_turn_state in [HumanTurnState.STARTING, HumanTurnState.MOVING, HumanTurnState.PLAYING_CARD]:
			enemy_turn_manager.update()
		clear_path()
	elif new_state == HumanTurnState.ACTION_TARGET:
		end_turn_button.disabled = true
		clear_path()
		create_target_area(active_character.get_id_position(), current_card.target_distance)
		create_cursor(tile_map_pos, direction)
	elif new_state == HumanTurnState.MOVING:
		end_turn_button.disabled = true
	elif new_state == HumanTurnState.PLAYING_CARD:
		end_turn_button.disabled = true
	elif new_state == HumanTurnState.PLAY_TELEPORTING:
		create_target_area(active_character.get_id_position(), teleport_distance)
		create_single_cursor(tile_map_pos)
	human_turn_state = new_state

func _on_end_turn_button_pressed():
	change_state(GameState.CPU_TURN)

func handle_move():
	# Current path is empty, so we can't move. Do nothing.
	if !valid_path or too_long_path:
		return
	change_human_turn_state(HumanTurnState.MOVING)
	# Save positions as they change.
	var original_pos = active_character.get_id_position()
	var final_pos = tile_map_pos
	var can_undo = await active_character.move(map_manager, final_pos)
	var move_cost = path_cost(current_path)
	active_character.reduce_move(move_cost)
	StatsManager.add(active_character, Stats.Field.MP_USED, move_cost)
	if can_undo:
		undo_button.show()
	else:
		reset_undo()
	character_moved.emit(final_pos)
	clear_enemy_info_cache()
	change_human_turn_state(HumanTurnState.WAITING)

func handle_teleport():
	# Allow to "skip" by allowing teleporting to current location.
	if tile_map_pos != active_character.get_id_position():
		# Don't teleport on top of something, except a treasure.
		if map_manager.is_solid(tile_map_pos, true, true, false):
			return
		var distance = map_manager.distance(active_character.get_id_position(), tile_map_pos)
		if distance > teleport_distance:
			return
		# TODO: Handle teleport "animation".
		await map_manager.move_character(active_character.get_id_position(), tile_map_pos)
		active_character.set_id_position(tile_map_pos)
		character_moved.emit(tile_map_pos)
		clear_enemy_info_cache()
	target_area.queue_free()
	single_cursor.queue_free()
	change_human_turn_state(HumanTurnState.PLAYING_CARD)
	teleport_finished.emit()

func _input(event):
	if Input.is_action_just_released("ui_cancel"):
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.ACTION_TARGET:
				hand_ui.get_child(current_card_index).set_highlight(false)
				current_card_index = -1
				current_card = null
				target_cursor.queue_free()
				target_area.queue_free()
				active_character.clear_pending_action_cost()
				change_human_turn_state(HumanTurnState.WAITING)
				get_viewport().set_input_as_handled()
	if Input.is_action_pressed("ui_showenemymove"):
		show_enemy_moves()
	if Input.is_action_just_released("ui_showenemymove"):
		clear_enemy_info()
	if Input.is_action_just_released("ui_focus_next"):
		set_active_character(active_character_index+1)

func show_enemy_moves():
	var final_walkable_cells = Dictionary()
	var final_attackable_cells = Dictionary()
	for enemy in enemies_node.get_children():
		var walkable_cells = get_enemy_walkable_cells(enemy)
		for cell in walkable_cells:
			if cell not in final_attackable_cells:
				final_walkable_cells[cell] = true
		var attackable_cells = get_enemy_attackable_cells(enemy)
		for cell in attackable_cells:
			if not cell in final_attackable_cells:
				final_attackable_cells[cell] = 0
			final_attackable_cells[cell] += 1
			if final_walkable_cells.has(cell):
				final_walkable_cells.erase(cell)
	enemy_move_area.set_tiles(final_walkable_cells.keys())
	enemy_move_area.visible = true
	enemy_attack_area.set_labeled_tiles(final_attackable_cells)
	enemy_attack_area.visible = true

func get_enemy_walkable_cells(enemy: Enemy):
	if enemy_walkable_cache.has(enemy):
		return enemy_walkable_cache[enemy]
	var walkable_cells = map_manager.get_walkable_cells(enemy.get_id_position(), enemy.move_points)
	enemy_walkable_cache[enemy] = walkable_cells
	return walkable_cells

func get_enemy_attackable_cells(enemy: Enemy):
	if enemy_attackable_cache.has(enemy):
		return enemy_attackable_cache[enemy]
	var walkable_cells = get_enemy_walkable_cells(enemy)
	var attackable_cells = get_attack_cells(enemy, walkable_cells)
	enemy_attackable_cache[enemy] = attackable_cells
	return attackable_cells

func get_enemy_attackable_not_walkable_cells(enemy: Enemy):
	var walkable_cells = get_enemy_walkable_cells(enemy)
	var walkable = {}
	for cell in walkable_cells:
		walkable[cell] = true
	var attackable_cells = get_attack_cells(enemy, walkable_cells)
	var attackable_not_walkable = []
	for cell in attackable_cells:
		if not walkable.has(cell):
			attackable_not_walkable.push_back(cell)
	return attackable_not_walkable

func clear_enemy_info_cache():
	enemy_walkable_cache.clear()
	enemy_attackable_cache.clear()

func update_enemy_info(enemy: Enemy):
	if Input.is_action_pressed("ui_showenemymove"):
		return
	enemy_info.text = enemy.info_text()
	var walkable_cells = get_enemy_walkable_cells(enemy)
	var attackable_cells = get_enemy_attackable_not_walkable_cells(enemy)
	update_move_area(walkable_cells, attackable_cells)

func clear_enemy_info():
	enemy_info.text = ""
	if Input.is_action_pressed("ui_showenemymove"):
		return
	enemy_move_area.visible = false
	enemy_attack_area.visible = false

func handle_enemy_death(enemy: Enemy):
	StatsManager.add(active_character, Stats.Field.ENEMIES_KILLED, 1)
	var pos = enemy.get_id_position()
	map_manager.remove_enemy(pos)
	enemy.queue_free()
	enemy_died.emit()

func handle_character_death(character: Character):
	var pos = character.get_id_position()
	map_manager.remove_character(pos)
	# Handle this in a fancier way, update portrait to show
	# character is dead, but don't remove from screen, etc.
	party.remove_child(character)
	character.queue_free()
	if not party.get_children().is_empty():
		set_active_character(0)
		reset_undo()
	else:
		StatsManager.remove_level(StatsManager.Level.TURN)
		game_over.emit()

func clear_effects():
	for effect in effects.get_children():
		effect.queue_free()

func play_card():
	change_human_turn_state(HumanTurnState.PLAYING_CARD)
	# Discard card first.
	if current_card.should_exhaust():
		active_character.deck.exhaust_card(current_card_index)
	else:
		active_character.deck.discard_card(current_card_index)
	# Take snapshot of current state before playing card.
	active_character.snap()
	if current_card.target_mode == Card.TargetMode.SELF:
		await current_card.apply_self(active_character)
	elif current_card.target_mode in [Card.TargetMode.ENEMY, Card.TargetMode.AREA]:
		await current_card.apply_self_effects(active_character)
		var target_tile = tile_map_pos
		var affected_tiles = current_card.effect_area(direction)
		var effect_time = 0
		for tile_offset in affected_tiles:
			var tile = target_tile + tile_offset
			var effect = animation_manager.get_effect(current_card.target_animation)
			if effect != null:
				effect.origin = active_character.global_position
				effect.target = map_manager.get_world_position(tile)
				effects.add_child(effect)
				effect_time = effect.apply_effect_time()
		if effects.get_child_count() != 0:
			await get_tree().create_timer(effect_time, false).timeout
		for tile_offset in affected_tiles:
			var tile = target_tile + tile_offset
			if map_manager.enemy_locs.has(tile):
				var enemy = map_manager.enemy_locs[tile]
				# TODO: Move this inside character.
				if current_card.apply_enemy(active_character, enemy):
					handle_enemy_death(enemy)
					active_character.killed_enemy.emit(active_character)
		if current_card.is_attack():
			active_character.attacked.emit(active_character)
	for effect in effects.get_children():
		await effect.finished()
	clear_effects()
	await current_card.apply_after_effects(active_character)
	StatsManager.add(active_character, Stats.Field.CARDS_PLAYED, 1)
	StatsManager.add(active_character, Stats.Field.AP_USED, current_card.cost)
	active_character.action_points -= current_card.cost
	active_character.card_played.emit(active_character, current_card)
	draw_hand()
	if map_manager.enemy_locs.is_empty():
		all_enemies_died.emit()
	# Consider wrapping all this into a method.
	current_card_index = -1
	current_card = null
	target_area.queue_free()
	target_cursor.queue_free()
	active_character.clear_pending_action_cost()
	reset_undo()
	clear_enemy_info_cache()
	change_human_turn_state(HumanTurnState.WAITING)

func teleport(character: Character, distance: int):
	teleport_distance = distance
	change_human_turn_state(HumanTurnState.PLAY_TELEPORTING)
	await teleport_finished

func update_target(new_tile_map_pos: Vector2i, new_direction: Vector2):
	valid_target = false
	# For target mode SELF, allow clicking anywhere.
	if current_card.target_mode == Card.TargetMode.SELF:
		valid_target = true
	elif current_card.target_mode == Card.TargetMode.ENEMY:
		target_cursor.update(new_tile_map_pos, new_direction)
		var distance = map_manager.distance(active_character.get_id_position(), new_tile_map_pos)
		var visible_tiles = map_manager.fov.get_fov(active_character.get_id_position())
		if distance > current_card.target_distance or not new_tile_map_pos in visible_tiles:
			valid_target = false
			target_cursor.set_color(Color(0, 0, 0, 1))
		else:
			if map_manager.enemy_locs.has(new_tile_map_pos):
				target_cursor.set_color(Color(1, 0, 0, 1))
				valid_target = true
			else:
				target_cursor.set_color(Color(1, 1, 1, 1))
	elif current_card.target_mode == Card.TargetMode.AREA:
		target_cursor.update(new_tile_map_pos, new_direction)
		var distance = map_manager.distance(active_character.get_id_position(), new_tile_map_pos)
		var visible_tiles = map_manager.fov.get_fov(active_character.get_id_position())
		if distance > current_card.target_distance or not new_tile_map_pos in visible_tiles:
			valid_target = false
			target_cursor.set_color(Color(0, 0, 0, 1))
		else:
			target_cursor.set_color(Color(1, 0, 0, 1))
			valid_target = true

func snap_to_direction(vector: Vector2) -> Vector2:
	var min_distance = null
	var direction = null
	for v in [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT]:
		var distance = vector.distance_squared_to(v)
		if min_distance == null:
			min_distance = distance
			direction = v
		else:
			if distance < min_distance:
				min_distance = distance
				direction = v
	return direction

func mouse_pos_to_plane_pos(mouse_pos: Vector2) -> Vector3:
	var camera_from = camera.project_ray_origin(mouse_pos)
	var camera_to = camera.project_ray_normal(mouse_pos)
	var n = Vector3(0, 1, 0) # plane normal
	var p = camera_from
	var v = camera_to
	# distance from plane
	var d = -2
	var t = - (n.dot(p) + d) / n.dot(v)
	var position = p + t * v
	return position

func plane_pos_to_tile_pos(plane_pos: Vector3) -> Vector2i:
	return Vector2i(floor(plane_pos.x / tile_size), floor(plane_pos.z / tile_size))

func handle_tile_change(new_tile_map_pos: Vector2i, new_direction: Vector2):
	var tile_changed = tile_map_pos != new_tile_map_pos
	var direction_changed = direction != new_direction

	# Ideally instead of this long method we can make all those
	# cursors, etc different objects, and have tile_changed,
	# direction_changed signal and have them react to that on their own.
	if tile_changed:
		if map_manager.enemy_locs.has(new_tile_map_pos):
			update_enemy_info(map_manager.enemy_locs[new_tile_map_pos])
		else:
			clear_enemy_info()
		if map_manager.treasure_locs.has(new_tile_map_pos):
			var treasure = map_manager.treasure_locs[new_tile_map_pos]
			treasure_info.text = "Treasure: %s (%d turns left)" % [treasure.get_description(active_character), treasure.turns_left]
		else:
			treasure_info.text = ""
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.WAITING:
				calculate_path(new_tile_map_pos)
			elif human_turn_state == HumanTurnState.PLAY_TELEPORTING:
				single_cursor.update(new_tile_map_pos)
	if tile_changed or direction_changed:
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.ACTION_TARGET:
				update_target(new_tile_map_pos, new_direction)

func update_position_direction(mouse_position: Vector2):
	var plane_pos = mouse_pos_to_plane_pos(mouse_position)
	var new_tile_map_pos = plane_pos_to_tile_pos(plane_pos)
	var offset = plane_pos - active_character.get_position()
	var new_direction = snap_to_direction(Vector2(offset.x, offset.z))
	if new_tile_map_pos != tile_map_pos or new_direction != direction:
		handle_tile_change(new_tile_map_pos, new_direction)
	tile_map_pos = new_tile_map_pos
	direction = new_direction

func _unhandled_input(event):
	if state == GameState.HUMAN_TURN:
		if state == HumanTurnState.MOVING or state == HumanTurnState.PLAYING_CARD:
			return
		if event is InputEventMouseButton:
			var mouse_event = event as InputEventMouseButton
			# left click
			if mouse_event.button_index == 1 and mouse_event.pressed:
				# move
				if human_turn_state == HumanTurnState.WAITING:
					handle_move()
				elif human_turn_state == HumanTurnState.PLAY_TELEPORTING:
					handle_teleport()
				elif human_turn_state == HumanTurnState.ACTION_TARGET:
					if valid_target:
						await play_card()
		elif event is InputEventMouseMotion:
			update_position_direction(event.position)

func _on_undo_button_pressed():
	apply_undo()

func get_save_state():
	var combat_state = CombatSaveState.new()
	combat_state.turn_number = turn_number
	for enemy in enemies_node.get_children():
		combat_state.enemies.push_back(enemy.get_save_state())
	for treasure in treasures.get_children():
		combat_state.treasures.push_back(treasure.get_save_state())
	return combat_state

func can_save():
	return state == GameState.HUMAN_TURN and human_turn_state == HumanTurnState.WAITING

# Invoked when abandoning run while this stage is on.
func cleanup():
	StatsManager.remove_level(StatsManager.Level.TURN)
