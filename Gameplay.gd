extends Node

enum GameState {
  HUMAN_TURN,
  CPU_TURN,
  NEW_STAGE,
}

var state_text = {
	GameState.NEW_STAGE: "New stage",
	GameState.HUMAN_TURN: "Your turn",
	GameState.CPU_TURN: "Enemy turn",
}

enum HumanTurnState {
	# Waiting for move or action to be chosen.
	# During this move we show move paths based on mouse pointer.
	WAITING,
	# Executing a move. No actions can be chosen, no character change, etc
	MOVING,
	# An action has been chosen and we are waiting to choose a target.
	ACTION_TARGET,
}

var turn_number = 0
var portrait_scene = preload("res://character_portrait.tscn")
var card_ui_scene = preload("res://card_ui.tscn")
var active_character: Character
# Direction of mouse position respect active character.
# E.g. Vector2.right if it's more to the right than up/down.
var direction: Vector2
var state: GameState
var human_turn_state: HumanTurnState
var map_manager = MapManager.new()
var current_path: PackedVector2Array = PackedVector2Array()
var valid_path: bool = false
var too_long_path: bool = false
# Whether the current tile is a valid target (in ACTION_TARGET mode).
var valid_target: bool = false
var tile_map_pos: Vector2i = Vector2i(0, 0)

var current_card_index: int = -1
var current_card: Card
var target_cursor: Node2D
var target_area: Node2D
var enemy_move_area: Node2D

var camera_panning_speed = 12
var camera_rotation_speed = 100

# Move somewhere where it can be used from anywhere or figure out how to pass.
var tile_size: int = 2
var half_tile2 = Vector2(tile_size/2, tile_size/2)
var half_tile3 = Vector3(tile_size/2, 0, tile_size/2)
var enemy_turn_thread = Thread.new()
var enemy_turn_calculated = false
var enemy_moving = false
var enemy_turn = EnemyTurn.new()

@onready var hand_ui = $UI/CardAreaHBox/Hand
@onready var deck_ui = $UI/CardAreaHBox/Deck
@onready var discard_ui = $UI/CardAreaHBox/Discard
@onready var camera = $Pivot/Camera3D

var stages = [
	preload("res://stage1.tscn"),
	preload("res://stage2.tscn"),
]
var stage: Stage
var stage_number: int

signal enemy_died
signal character_moved(pos: Vector2i)
signal all_enemies_died
signal new_turn_started(turn: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	stage_number = 0
	var i = 0
	for character in $World/Party.get_children():
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		# Add portraits in UI.
		$UI/CharacterState.add_child(character_portrait)
		# Set portrait on character so it can update when e.g. move points change
		character.set_portrait(character_portrait)
		# Hook character selection.
		character_portrait.get_portrait_button().pressed.connect(_on_character_portrait_pressed.bind(i))
		i += 1
	initialize_stage(stage_number)

func initialize_stage(stage_number: int):
	stage = stages[stage_number].instantiate() as Stage
	connect("enemy_died", stage.enemy_died_handler)
	connect("character_moved", stage.character_moved_handler)
	connect("all_enemies_died", stage.all_enemies_died_handler)
	connect("new_turn_started", stage.new_turn_started_handler)
	stage.connect("stage_completed", next_stage)
	$World.add_child(stage)
	var i = 0
	for character in $World/Party.get_children():
		character.begin_stage()
		character.set_id_position(stage.starting_positions[i])
		i += 1
	# As of now, some bits of the game require active_character to be set,
	# so set it now before changing state.
	set_active_character(0)
	initialize_map_manager()
	change_state(GameState.HUMAN_TURN)

func next_stage():
	stage_number += 1
	change_state(GameState.NEW_STAGE)
	initialize_stage(stage_number)

func initialize_map_manager():
	map_manager.initialize(stage.gridmap)
	map_manager.set_party($World/Party.get_children())
	map_manager.set_enemies($World/Enemies.get_children())
	map_manager.initialize_a_star()
	enemy_turn.initialize(map_manager)

func _on_character_portrait_pressed(index: int):
	# Only allow to change active character during human turn on waiting state.
	if state != GameState.HUMAN_TURN or human_turn_state != HumanTurnState.WAITING:
		return
	# add some sub-state/bool for any actions being in progress
	set_active_character(index)

func draw_hand():
	# Clear hand.
	for child in hand_ui.get_children():
		child.queue_free()
	for j in active_character.deck.hand.size():
		var card = active_character.deck.hand[j]
		var new_card = card_ui_scene.instantiate() as CardUI
		new_card.initialize(card, _on_card_pressed.bind(j))
		hand_ui.add_child(new_card)
	# Clear discard.
	for child in discard_ui.get_children():
		child.queue_free()
	# Display last discarded card.
	if not active_character.deck.discard.is_empty():
		var new_card = card_ui_scene.instantiate() as CardUI
		new_card.initialize(active_character.deck.discard.back(), Callable())
		discard_ui.add_child(new_card)
		new_card.tooltip_text = "%d cards on discard pile" % active_character.deck.discard.size()
	# Set deck tooltip.
	deck_ui.tooltip_text = "%d cards on deck" % active_character.deck.cards.size()
	
func set_active_character(index: int):
	var i = 0
		
	for character in $World/Party.get_children():
		if i == index:
			active_character = $World/Party.get_child(i)
			active_character.set_active(true)
			draw_hand()
		else:
			character.set_active(false)
			character.clear_pending_move_cost()
		i += 1
	
func _on_card_pressed(index: int):
	if state != GameState.HUMAN_TURN:
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

func change_cursor_color(color: Color):
	for line in target_cursor.get_children():
		line.default_color = color

func create_target_cursor(pos: Vector2i, direction: Vector2):
	var cursor = Node2D.new()
	for effect_pos in transformed_effect_area(direction):
		var new_line = draw_square(pos + effect_pos, 4, Color(1, 1, 1, 1))
		cursor.add_child(new_line)
	return cursor
	
func create_cursor(pos: Vector2i, direction: Vector2):
	var target_mode = current_card.target_mode
	if target_mode == Card.TargetMode.SELF:
		target_cursor = create_target_cursor(pos, direction)
		$World.add_child(target_cursor)
	elif target_mode == Card.TargetMode.ENEMY:
		# create tile cursor controlled by mouse,
		# that can only be clicked on top of monsters
		target_cursor = create_target_cursor(pos, direction)
		$World.add_child(target_cursor)
	elif target_mode == Card.TargetMode.AREA:
		pass

func add_unprojected_point(line: Line2D, world_pos: Vector3):
	var unprojected = camera.unproject_position(world_pos)
	line.add_point(unprojected)
	
func draw_square(pos: Vector2i, width: float, color=Color(1, 1, 1, 1)) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.width = width
	var start = map_manager.get_world_position_corner(pos)
	add_unprojected_point(line, start)
	add_unprojected_point(line, start + Vector3(tile_size, 0, 0))
	add_unprojected_point(line, start + Vector3(tile_size, 0, tile_size))
	add_unprojected_point(line, start + Vector3(0, 0, tile_size))
	add_unprojected_point(line, start)
	return line

func create_target_area(pos: Vector2i):
	# Respect line-of-sight here.
	if is_instance_valid(target_area):
			target_area.queue_free()
	target_area = Node2D.new()
	var center = Vector2i(0, 0)
	var target_type = current_card.target_mode 
	var i = -current_card.target_distance
	while i <= current_card.target_distance:
		var j = -current_card.target_distance
		while j <= current_card.target_distance:
			var offset = Vector2i(i, j)
			var new_pos = pos + offset
			if map_manager.in_bounds(new_pos) and not map_manager.is_solid(new_pos, false, false):
				if map_manager.distance(center, offset) <= current_card.target_distance:
					var new_line = draw_square(new_pos, 1)
					target_area.add_child(new_line)
			j += 1
		i += 1
	$World.add_child(target_area)

func update_move_area(positions: Array):
	if is_instance_valid(enemy_move_area):
		enemy_move_area.queue_free()
	enemy_move_area = Node2D.new()
	var red = Color(1, 0, 0, 1)
	for pos in positions:
		var new_line = draw_square(pos, 1, red)
		enemy_move_area.add_child(new_line)
	$World.add_child(enemy_move_area)
	
func path_cost(path: PackedVector2Array) -> float:
	var cost = 0.0
	for i in path.size()-1:
		var path_diff = path[i+1] - path[i]
		if path_diff[0] == 0 or path_diff[1] == 0:
			cost += 1.0
		else:
			cost += 1.5
	return cost

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
	if valid_path:
		if too_long_path:
			$World/Path.default_color = Color(1, 0, 0, 1)
		else:
			$World/Path.default_color = Color(1, 1, 1, 1)
		$World/Path.clear_points()
		for point in current_path:
			var location = map_manager.get_world_position(point)
			add_unprojected_point($World/Path, location)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == GameState.HUMAN_TURN:
		var camera_move = delta * camera_panning_speed
		var camera_rotate = delta * camera_rotation_speed
		var camera_forward = -camera.transform.basis.z
		camera_forward.y = 0
		var forward = camera_forward.normalized() * camera_move
		var camera_modified = false
		if Input.is_action_pressed("ui_right"):
			camera.position += forward.cross(Vector3.UP)
			camera_modified = true
		if Input.is_action_pressed("ui_left"):
			camera.position -= forward.cross(Vector3.UP)
			camera_modified = true
		if Input.is_action_pressed("ui_up"):
			camera.position += forward
			camera_modified = true
		if Input.is_action_pressed("ui_down"):
			camera.position -= forward
			camera_modified = true
		if Input.is_action_pressed("ui_rotate_left"):
			camera.rotate_y(camera_rotate*delta)
			camera_modified = true
		if Input.is_action_pressed("ui_rotate_right"):
			camera.rotate_y(-camera_rotate*delta)
			camera_modified = true
		if camera_modified:
			update_position_direction(get_viewport().get_mouse_position(), true)
	elif state == GameState.CPU_TURN:
		if enemy_turn_calculated and not enemy_moving:
			# Consider adding a CpuTurnState if needed.
			enemy_moving = true
			for move in enemy_turn.enemy_moves:
				# Move enemy.
				var enemy = move[0]
				var loc = move[1]
				var targets = move[2]
				var path = map_manager.get_enemy_path(enemy.get_id_position(), loc)
				var curve = curve_from_path(path)
				for point in curve.get_baked_points():
					enemy.look_at(point)
					enemy.position = point
					await get_tree().create_timer(0.01).timeout
				enemy.set_id_position(loc)
				# Find first target which is not dead yet.
				var chosen_target = null
				var target_character = null
				for target_distance in targets:
					var target = target_distance[0]
					if map_manager.character_locs.has(target):
						chosen_target = target_distance
						target_character = map_manager.character_locs[target]
						break
				# If no targets, continue.
				if chosen_target == null:
					continue
				if chosen_target[1] > enemy.attack_range:
					continue
				# We found a target within range, attack and destroy character if it died.
				if target_character.apply_attack(enemy):
					handle_character_death(target_character)
			enemy_moving = false
			change_state(GameState.HUMAN_TURN)

func _async_enemy_turn():
	var start = Time.get_ticks_msec()
	enemy_turn.calculate_moves()
	var end = Time.get_ticks_msec()
	print_debug("Enemy turn time ", end-start)
	call_deferred("_wait_enemy_turn_completed")

func _wait_enemy_turn_completed():
	var results = enemy_turn_thread.wait_to_finish()
	enemy_turn_calculated = true

func change_state(new_state):
	state = new_state
	$UI/InfoPanel/VBox/TurnState.text = state_text[state]
	if state == GameState.HUMAN_TURN:
		turn_number += 1
		for character in $World/Party.get_children():
			character.begin_turn()
		draw_hand()
		human_turn_state = HumanTurnState.WAITING
		new_turn_started.emit(turn_number)
	elif state == GameState.CPU_TURN:
		for enemy in $World/Enemies.get_children():
			enemy.begin_turn()
		enemy_turn_calculated = false
		enemy_turn_thread.start(_async_enemy_turn)
		

func change_human_turn_state(new_state):
	if new_state == HumanTurnState.WAITING:
		current_path.clear()
		$World/Path.clear_points()
	elif new_state == HumanTurnState.ACTION_TARGET:
		create_target_area(active_character.get_id_position())
		create_cursor(tile_map_pos, Vector2.RIGHT)
	elif new_state == HumanTurnState.MOVING:
		pass
	human_turn_state = new_state
	
func _on_end_turn_button_pressed():
	change_state(GameState.CPU_TURN)

func curve_from_path(path: PackedVector2Array) -> Curve3D:
	var curve = Curve3D.new()
	for pos in path:
		var world_pos = map_manager.get_world_position(pos)
		curve.add_point(world_pos)
	return curve
	
func handle_move(mouse_pos: Vector2):
	# Current path is empty, so we can't move. Do nothing.
	if !valid_path or too_long_path:
		return
	change_human_turn_state(HumanTurnState.MOVING)
	# Handle move "animation".
	var curve = curve_from_path(current_path)
	# Save final position as it may change while moving.
	var final_pos = tile_map_pos
	# Moving 1 "baked point" per 0.01 seconds, each point being
	# at a distance of 0.2 from each other.
	for point in curve.get_baked_points():
		active_character.look_at(point)
		active_character.position = point
		await get_tree().create_timer(0.01).timeout	
	active_character.reduce_move(path_cost(current_path))
	map_manager.move_character(active_character.get_id_position(), final_pos)
	active_character.set_id_position(final_pos)
	character_moved.emit(final_pos)
	change_human_turn_state(HumanTurnState.WAITING)
	
func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.ACTION_TARGET:
				hand_ui.get_child(current_card_index).set_highlight(false)
				current_card_index = -1
				current_card = null
				target_cursor.queue_free()
				target_area.queue_free()
				active_character.clear_pending_action_cost()
				change_human_turn_state(HumanTurnState.WAITING)

func update_enemy_info(enemy: Enemy):
	$UI/InfoPanel/VBox/EnemyInfo.text = enemy.info_text()
	var walkable_cells = map_manager.get_walkable_cells(enemy.get_id_position(), enemy.move_points)
	update_move_area(walkable_cells)

func clear_enemy_info():
	$UI/InfoPanel/VBox/EnemyInfo.text = ""
	if is_instance_valid(enemy_move_area):
		enemy_move_area.queue_free()

func handle_enemy_death(enemy: Enemy):
	var pos = enemy.get_id_position()
	map_manager.remove_enemy(pos)
	enemy.queue_free()
	enemy_died.emit()
	if map_manager.enemy_locs.is_empty():
		all_enemies_died.emit()
	
func handle_character_death(character: Character):
	var pos = character.get_id_position()
	map_manager.remove_character(pos)
	# Handle this in a fancier way, update portrait to show
	# character is dead, but don't remove from screen, etc.
	character.queue_free()
	if not $World/Party.get_children().is_empty():
		set_active_character(0)
	else:
		print_debug("Game over!")

func transformed_effect_area(direction: Vector2):
	var effect_area = current_card.effect_area()
	var new_effect_area = []
	var angle = Vector2.RIGHT.angle_to(direction)
	for pos in effect_area:
		new_effect_area.append(Vector2i(Vector2(pos).rotated(angle)))
	return new_effect_area
	
func play_card():
	if current_card.target_mode == Card.TargetMode.SELF:
		active_character.apply_card(current_card)
	elif current_card.target_mode == Card.TargetMode.ENEMY:
		var affected_tiles = transformed_effect_area(direction)
		for tile_offset in affected_tiles:
			if map_manager.enemy_locs.has(tile_map_pos + tile_offset):
				var enemy = map_manager.enemy_locs[tile_map_pos + tile_offset]
				if enemy.apply_card(current_card):
					handle_enemy_death(enemy)
	active_character.action_points -= current_card.cost
	active_character.deck.discard_card(current_card_index)
	draw_hand()
	# Consider wrapping all this into a method.
	current_card_index = -1
	current_card = null
	target_area.queue_free()
	target_cursor.queue_free()
	active_character.clear_pending_action_cost()
	change_human_turn_state(HumanTurnState.WAITING)

func update_target(new_tile_map_pos: Vector2i, new_direction: Vector2):
	valid_target = false
	# For target mode SELF, allow clicking anywhere.
	if current_card.target_mode == Card.TargetMode.SELF:
		valid_target = true
	elif current_card.target_mode == Card.TargetMode.ENEMY:
		if is_instance_valid(target_cursor):
			target_cursor.queue_free()
		create_cursor(new_tile_map_pos, new_direction)
		var distance = map_manager.distance(active_character.get_id_position(), new_tile_map_pos) 
		if distance > current_card.target_distance:
			valid_target = false
			change_cursor_color(Color(0, 0, 0, 1))
		else:
			if map_manager.enemy_locs.has(new_tile_map_pos):
				change_cursor_color(Color(1, 0, 0, 1))
				valid_target = true
			else:
				change_cursor_color(Color(1, 1, 1, 1))

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

func handle_tile_change(new_tile_map_pos: Vector2i, new_direction: Vector2, camera_changed: bool):
	var tile_changed = tile_map_pos != new_tile_map_pos
	var direction_changed = direction != new_direction
	
	# Ideally instead of this long method we can make all those
	# cursors, etc different objects, and have tile_changed,
	# direction_changed, camera_changed signals and have them
	# react to that on their own.
	if tile_changed or camera_changed:
		if map_manager.enemy_locs.has(new_tile_map_pos):
			update_enemy_info(map_manager.enemy_locs[new_tile_map_pos])
		else:
			clear_enemy_info()
		# If targeting, there should be a cursor and the cursor can be move around.
		# Likely this is only if target_mode is not SELF, will need to take that into account.
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.WAITING:
				calculate_path(new_tile_map_pos)
	if tile_changed or direction_changed or camera_changed:
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.ACTION_TARGET:
				update_target(new_tile_map_pos, new_direction)
	if camera_changed:
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.ACTION_TARGET:
				create_target_area(active_character.get_id_position())

func update_position_direction(mouse_position: Vector2, camera_updated=false):
	var plane_pos = mouse_pos_to_plane_pos(mouse_position)
	var new_tile_map_pos = plane_pos_to_tile_pos(plane_pos)
	var offset = plane_pos - active_character.get_position()
	var new_direction = snap_to_direction(Vector2(offset.x, offset.z))
	if new_tile_map_pos != tile_map_pos or new_direction != direction or camera_updated:
		handle_tile_change(new_tile_map_pos, new_direction, camera_updated)
	tile_map_pos = new_tile_map_pos
	direction = new_direction

func _unhandled_input(event):
	if state == GameState.HUMAN_TURN:
		if event is InputEventMouseButton:
			var mouse_event = event as InputEventMouseButton
			# left click
			if mouse_event.button_index == 1 and mouse_event.pressed:
				# move
				if human_turn_state == HumanTurnState.WAITING:
					handle_move(mouse_event.position)
				elif human_turn_state == HumanTurnState.ACTION_TARGET:
					if valid_target:
						play_card()
		elif event is InputEventMouseMotion:
			update_position_direction(event.position)
