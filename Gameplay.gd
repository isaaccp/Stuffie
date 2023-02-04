extends Node

enum GameState {
  HUMAN_TURN,
  CPU_TURN,
}

var state_text = {
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

var portrait_scene = preload("res://character_portrait.tscn")
var card_ui_scene = preload("res://card_ui.tscn")
var active_character: Character

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
var target_cursor: Line2D
var target_area: Node2D
var enemy_move_area: Node2D

# Move somewhere where it can be used from anywhere or figure out how to pass.
var tile_size: int = 16

var enemy_turn_thread = Thread.new()
var enemy_turn_calculated = false
var enemy_turn = EnemyTurn.new()

@onready var hand_ui = $UI/CardAreaHBox/Hand
@onready var deck_ui = $UI/CardAreaHBox/Deck
@onready var discard_ui = $UI/CardAreaHBox/Discard

# Called when the node enters the scene tree for the first time.
func _ready():
	var i = 0
	for character in $World/Party.get_children():
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		# Add portraits in UI.
		$UI/CharacterState.add_child(character_portrait)
		# Set portrait on character so it can update when e.g. move points change
		character.set_portrait(character_portrait)
		character.set_id_position(Vector2i(i, i))
		# Hook character selection.
		character_portrait.get_portrait_button().pressed.connect(_on_character_portrait_pressed.bind(i))
		i += 1
	# As of now, some bits of the game require active_character to be set,
	# so set it now before changing state.
	set_active_character(0)
	change_state(GameState.HUMAN_TURN)
	initialize_map_manager()
	
func initialize_map_manager():
	map_manager.initialize($World/TileMap)
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
		
func create_cursor(card: Card):
	var target_mode = card.target_mode
	if target_mode == Card.TargetMode.SELF:
		target_cursor = draw_square(Vector2i(0, 0), 2)
		target_cursor.global_position = active_character.get_id_position() * tile_size
		$World.add_child(target_cursor)
	elif target_mode == Card.TargetMode.ENEMY:
		# create single tile cursor controlled by mouse,
		# that can only be clicked on top of monsters
		target_cursor = draw_square(Vector2i(0, 0), 2)
		target_cursor.global_position = tile_map_pos * tile_size
		$World.add_child(target_cursor)
	elif target_mode == Card.TargetMode.AREA:
		pass

func draw_square(pos: Vector2i, width: float, color=Color(1, 1, 1, 1)) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.width = width
	line.add_point(pos * tile_size)
	line.add_point(pos * tile_size + Vector2i(0, tile_size))
	line.add_point(pos * tile_size + Vector2i(tile_size, tile_size))
	line.add_point(pos * tile_size + Vector2i(tile_size, 0))
	line.add_point(pos * tile_size)
	return line

func create_target_area(card: Card):
	target_area = Node2D.new()
	var center = Vector2i(0, 0)
	var i = -card.target_distance
	while i <= card.target_distance:
		var j = -card.target_distance
		while j <= card.target_distance:
			if map_manager.distance(center, Vector2i(i, j)) <= card.target_distance:
				var new_line = draw_square(Vector2(i, j), 0.5)
				target_area.add_child(new_line)
			j += 1
		i += 1
	target_area.global_position = active_character.get_id_position() * tile_size
	$World.add_child(target_area)

func update_move_area(positions: Array):
	if is_instance_valid(enemy_move_area):
		enemy_move_area.queue_free()
	enemy_move_area = Node2D.new()
	var red = Color(1, 0, 0, 1)
	for pos in positions:
		var new_line = draw_square(pos, 0.5, red)
		enemy_move_area.add_child(new_line)
	# move_area.global_position = active_character.get_id_position() * tile_size
	$World.add_child(enemy_move_area)
	
func convert_mouse_pos_to_tile(absolute_mouse_pos: Vector2) -> Vector2i:
	var transform = get_viewport().get_canvas_transform().affine_inverse()
	var mouse_pos = transform.basis_xform(absolute_mouse_pos)
	return Vector2i($World/TileMap.local_to_map(mouse_pos))
	
func path_cost(path: PackedVector2Array) -> float:
	var cost = 0.0
	for i in path.size()-1:
		var path_diff = path[i+1] - path[i]
		if path_diff[0] == 0 or path_diff[1] == 0:
			cost += 1.0
		else:
			cost += 1.5
	return cost

func get_current_mouse_tile_map_pos():
	var absolute_mouse_pos = get_viewport().get_mouse_position()
	return convert_mouse_pos_to_tile(absolute_mouse_pos)
	
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
		var half_tile = Vector2(tile_size/2, tile_size/2)
		$World/Path.clear_points()
		for point in current_path:
			$World/Path.add_point(point*tile_size+half_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == GameState.HUMAN_TURN:
		pass
	elif state == GameState.CPU_TURN:
		if enemy_turn_calculated:
			for move in enemy_turn.enemy_moves:
				var enemy = move[0]
				var loc = move[1]
				enemy.set_id_position(loc)
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
		for character in $World/Party.get_children():
			character.begin_turn()
		draw_hand()
		human_turn_state = HumanTurnState.WAITING
	elif state == GameState.CPU_TURN:
		for enemy in $World/Enemies.get_children():
			enemy.begin_turn()
		enemy_turn_calculated = false
		enemy_turn_thread.start(_async_enemy_turn)
		

func change_human_turn_state(new_state):
	human_turn_state = new_state
	current_path.clear()
	$World/Path.clear_points()
	if new_state == HumanTurnState.ACTION_TARGET:
		create_target_area(current_card)
		create_cursor(current_card)
	
func _on_end_turn_button_pressed():
	change_state(GameState.CPU_TURN)

func handle_move(mouse_pos: Vector2):
	# Current path is empty, so we can't move. Do nothing.
	if !valid_path or too_long_path:
		return
	var new_pos = convert_mouse_pos_to_tile(mouse_pos)
	# Handle move "animation".
	var old_pos = active_character.get_id_position()
	active_character.reduce_move(path_cost(current_path))
	active_character.set_id_position(new_pos)
	map_manager.move_character(old_pos, new_pos)
	current_path.clear()
	$World/Path.clear_points()
	
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
	
func play_card():
	if current_card.target_mode == Card.TargetMode.SELF:
		active_character.apply_card(current_card)
	elif current_card.target_mode == Card.TargetMode.ENEMY:
		var enemy = map_manager.enemy_locs[tile_map_pos]
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

func update_target(new_tile_map_pos: Vector2i):
	valid_target = false
	# For target mode SELF, allow clicking anywhere.
	if current_card.target_mode == Card.TargetMode.SELF:
		valid_target = true
	elif current_card.target_mode == Card.TargetMode.ENEMY:
		target_cursor.global_position = new_tile_map_pos*tile_size
		var distance = map_manager.distance(active_character.get_id_position(), new_tile_map_pos) 
		if distance > current_card.target_distance:
			valid_target = false
			target_cursor.default_color = Color(0, 0, 0, 1)
		else:
			if map_manager.enemy_locs.has(new_tile_map_pos):
				target_cursor.default_color = Color(1, 0, 0, 1)
				valid_target = true
			else:
				target_cursor.default_color = Color(1, 1, 1, 1)

func handle_tile_change(new_tile_map_pos: Vector2i):
	if map_manager.enemy_locs.has(new_tile_map_pos):
		update_enemy_info(map_manager.enemy_locs[new_tile_map_pos])
	else:
		clear_enemy_info()
	# If targeting, there should be a cursor and the cursor can be move around.
	# Likely this is only if target_mode is not SELF, will need to take that into account.
	if state == GameState.HUMAN_TURN:
		if human_turn_state == HumanTurnState.WAITING:
			calculate_path(new_tile_map_pos)
		elif human_turn_state == HumanTurnState.ACTION_TARGET:
			update_target(new_tile_map_pos)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		# left click
		if mouse_event.button_index == 1 and mouse_event.pressed:
			# move
			if state == GameState.HUMAN_TURN:
				if human_turn_state == HumanTurnState.WAITING:
					handle_move(mouse_event.position)
				elif human_turn_state == HumanTurnState.ACTION_TARGET:
					if valid_target:
						play_card()
	elif event is InputEventMouseMotion:
		var new_tile_map_pos = convert_mouse_pos_to_tile(event.position)
		# Handle enemy mouseover. It seems like it's fine to allow this
		# regardless of turn, etc.
		if new_tile_map_pos != tile_map_pos:
			handle_tile_change(new_tile_map_pos)
		tile_map_pos = new_tile_map_pos
