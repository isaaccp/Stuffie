extends Node

enum MainGameState {
	MAIN_MENU,
	WITHIN_RUN,
}

var state = null

var main_menu_scene = preload("res://main_menu.tscn")
var game_run_scene = preload("res://game_run.tscn")

func _ready():
	change_state(MainGameState.MAIN_MENU)

func change_state(new_state: MainGameState):
	if state == new_state:
		return
	for node in get_children():
		node.queue_free()
	if new_state == MainGameState.MAIN_MENU:
		var main_menu = main_menu_scene.instantiate()
		add_child(main_menu)
		main_menu.connect("new_game_selected", start_run)
	elif new_state == MainGameState.WITHIN_RUN:
		var game_run = game_run_scene.instantiate()
		game_run.connect("run_finished", finish_run)
		add_child(game_run)
		
func start_run():
	change_state(MainGameState.WITHIN_RUN)
	
func finish_run():
	change_state(MainGameState.MAIN_MENU)
