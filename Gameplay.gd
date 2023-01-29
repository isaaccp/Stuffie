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

# Called when the node enters the scene tree for the first time.
func _ready():
	var i = 0
	for character in $World/Party.get_children():
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		# Add portraits in UI
		$UI/CharacterState.add_child(character_portrait)
		character.set_portrait(character_portrait)
		character_portrait.get_node('Portrait').pressed.connect(_on_character_portrait_pressed.bind(i))
		i += 1
	set_active_character(0)
	change_state(GameState.HUMAN_TURN)

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
