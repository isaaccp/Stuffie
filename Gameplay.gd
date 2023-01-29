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
var cpu_turn_start = -1
var a_star: AStarGrid2D
var current_path: PackedVector2Array = PackedVector2Array()
var valid_path: bool = false
var too_long_path: bool = false

var current_card_index: int = -1
var current_card: Card
var target_mode: Card.TargetMode

# Move somewhere where it can be used from anywhere or figure out how to pass.
var tile_size: int = 16

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
	change_state(GameState.HUMAN_TURN)
	set_active_character(0)
	build_a_star()
	
func build_a_star():
	a_star = AStarGrid2D.new()
	var map_rect = $World/TileMap.get_used_rect()
	a_star.size = map_rect.size
	a_star.cell_size = Vector2(tile_size, tile_size)
	a_star.diagonal_mode = a_star.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE 
	a_star.update()
	
	# Base map.
	for i in map_rect.size[0]:
		for j in map_rect.size[1]:
			var tile_data = $World/TileMap.get_cell_tile_data(0, Vector2i(i, j))
			var solid = tile_data.get_custom_data("Solid") as bool
			if solid:
				a_star.set_point_solid(Vector2i(i, j))

	# Obstacles layer.
	for pos in $World/TileMap.get_used_cells(1):
		a_star.set_point_solid(pos)
		
	# Characters.
	for character in $World/Party.get_children():
		a_star.set_point_solid(character.get_id_position())

func _on_character_portrait_pressed(index: int):
	# Only allow to change active character during human turn on waiting state.
	if state != GameState.HUMAN_TURN or human_turn_state != HumanTurnState.WAITING:
		return
	# add some sub-state/bool for any actions being in progress
	set_active_character(index)
	
func set_active_character(index: int):
	var i = 0
	# Clear hand for prevoius character.
	for child in $UI/Hand.get_children():
		child.queue_free()
		
	for character in $World/Party.get_children():
		if i == index:
			active_character = $World/Party.get_child(i)
			active_character.set_active(true)
			for j in active_character.hand.cards.size():
				var card = active_character.hand.cards[j]
				var new_card = card_ui_scene.instantiate() as CardUI
				new_card.initialize(card, _on_card_pressed.bind(j))
				$UI/Hand.add_child(new_card)
		else:
			character.set_active(false)
			character.clear_pending_move_cost()
		i += 1
	
func _on_card_pressed(index: int):
	if state != GameState.HUMAN_TURN:
		return
	
	if current_card_index != -1:
		$UI/Hand.get_child(current_card_index).set_highlight(false)
	
	$UI/Hand.get_child(index).set_highlight(true)
	current_card_index = index
	current_card = active_character.hand.cards[index]
	
	# Possibly there are some 'target-less' cards that can take effect right away.
	change_human_turn_state(HumanTurnState.ACTION_TARGET)
	target_mode = current_card.target_mode
	print_debug("Card clicked", index)
	
func convert_mouse_pos_to_tile(absolute_mouse_pos: Vector2) -> Vector2:
	var transform = get_viewport().get_canvas_transform().affine_inverse()
	var mouse_pos = transform.basis_xform(absolute_mouse_pos)
	return $World/TileMap.local_to_map(mouse_pos)
	
func path_cost(path: PackedVector2Array) -> float:
	var cost = 0.0
	for i in path.size()-1:
		var path_diff = path[i+1] - path[i]
		if path_diff[0] == 0 or path_diff[1] == 0:
			cost += 1.0
		else:
			cost += 1.5
	return cost
		

func process_human_waiting():
			# Active charater position
	var pos = active_character.get_id_position()
			# Calculate mouse pointer position on the tilemap
	var absolute_mouse_pos = get_viewport().get_mouse_position()
	var tile_map_pos = convert_mouse_pos_to_tile(absolute_mouse_pos)
	current_path = a_star.get_id_path(pos, tile_map_pos)
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
			$World/Line2D.default_color = Color(1, 0, 0, 1)
		else:
			$World/Line2D.default_color = Color(1, 1, 1, 1)
		var half_tile = Vector2(tile_size/2, tile_size/2)
		$World/Line2D.clear_points()
		for point in current_path:
			$World/Line2D.add_point(point*tile_size+half_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == GameState.HUMAN_TURN:
		if human_turn_state == HumanTurnState.WAITING:
			process_human_waiting()
		elif human_turn_state == HumanTurnState.ACTION_TARGET:
			if target_mode == Card.TargetMode.SELF:
				pass
			elif target_mode == Card.TargetMode.ENEMY:
				pass
			elif target_mode == Card.TargetMode.AREA:
				pass
	else:
		if cpu_turn_start == -1:
			cpu_turn_start = Time.get_ticks_msec()
		if Time.get_ticks_msec() - cpu_turn_start > 1000:
			change_state(GameState.HUMAN_TURN)
			cpu_turn_start = -1
		

func change_state(new_state):
	state = new_state
	$UI/TurnState.text = state_text[state]
	if state == GameState.HUMAN_TURN:
		for character in $World/Party.get_children():
			character.begin_turn()
		human_turn_state = HumanTurnState.WAITING

func change_human_turn_state(new_state):
	human_turn_state = new_state
	current_path.clear()
	$World/Line2D.clear_points()
	
func _on_end_turn_button_pressed():
	change_state(GameState.CPU_TURN)

func handle_move(mouse_pos: Vector2):
	# Current path is empty, so we can't move. Do nothing.
	if !valid_path or too_long_path:
		return
	var tile_map_pos = convert_mouse_pos_to_tile(mouse_pos)
	# Handle move "animation".
	a_star.set_point_solid(active_character.get_id_position(), false)
	active_character.reduce_move(path_cost(current_path))
	active_character.set_id_position(tile_map_pos)
	a_star.set_point_solid(active_character.get_id_position())

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		if state == GameState.HUMAN_TURN:
			if human_turn_state == HumanTurnState.ACTION_TARGET:
				$UI/Hand.get_child(current_card_index).set_highlight(false)
				current_card_index = -1
				current_card = null
				change_human_turn_state(HumanTurnState.WAITING)
		
func _unhandled_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		# left click
		if mouse_event.button_index == 1 and mouse_event.pressed:
			# move
			if state == GameState.HUMAN_TURN and human_turn_state == HumanTurnState.WAITING:
				handle_move(mouse_event.position)
