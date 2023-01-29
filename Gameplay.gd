extends Node

enum GameState {
  HUMAN_TURN,
  CPU_TURN,
}

var state_text = {
	GameState.HUMAN_TURN: "Your turn",
	GameState.CPU_TURN: "Enemy turn",
}

var portrait_scene = preload("res://character_portrait.tscn")

var active_character: Character

var state
var cpu_turn_start = -1
var a_star
var path

# Called when the node enters the scene tree for the first time.
func _ready():
	var i = 0
	for character in $World/Party.get_children():
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		# Add portraits in UI.
		$UI/CharacterState.add_child(character_portrait)
		# Set portrait on character so it can update when e.g. move points change
		character.set_portrait(character_portrait)
		# Hook character selection.
		character_portrait.get_node('Portrait').pressed.connect(_on_character_portrait_pressed.bind(i))
		i += 1
	set_active_character(0)
	change_state(GameState.HUMAN_TURN)
	build_a_star()
	path = a_star.get_point_path(Vector2i(3, 3), Vector2i(32, 20))
	print_debug(path)
	for point in path:
		$World/Line2D.add_point(point+Vector2(8,8))
	
func build_a_star():
	a_star = AStarGrid2D.new()
	var map_rect = $World/TileMap.get_used_rect()
	a_star.size = map_rect.size
	a_star.cell_size = Vector2(16, 16)
	a_star.diagonal_mode = a_star.DIAGONAL_MODE_NEVER
	a_star.set_default_estimate_heuristic(AStarGrid2D.HEURISTIC_CHEBYSHEV)
	a_star.set_default_compute_heuristic(AStarGrid2D.HEURISTIC_CHEBYSHEV)
	a_star.update()
	for i in map_rect.size[0]:
		for j in map_rect.size[1]:
			var tile_data = $World/TileMap.get_cell_tile_data(0, Vector2i(i, j))
			var solid = tile_data.get_custom_data("Solid") as bool
			if solid:
				a_star.set_point_solid(Vector2i(i, j))

	for pos in $World/TileMap.get_used_cells(1):
		a_star.set_point_solid(pos)

func _on_character_portrait_pressed(index: int):
	if state != GameState.HUMAN_TURN:
		return
	# add some sub-state/bool for any actions being in progress
	set_active_character(index)
	
func set_active_character(index: int):
	var i = 0
	for character in $World/Party.get_children():
		if i == index:
			active_character = $World/Party.get_child(i)
			active_character.set_active(true)
		else:
			character.set_active(false)
		i += 1
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == GameState.HUMAN_TURN:
		# wait for human to finish turn
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
	
func _on_end_turn_button_pressed():
	change_state(GameState.CPU_TURN)
	
func _on_character_button_pressed():
	pass
