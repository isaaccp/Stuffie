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

var state
var cpu_turn_start = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	for character in $World/Party.get_children():
		var character_portrait = portrait_scene.instantiate() as CharacterPortrait
		$UI/CharacterState.add_child(character_portrait)
		character.set_portrait(character_portrait)
	change_state(GameState.HUMAN_TURN)

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
