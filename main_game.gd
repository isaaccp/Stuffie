extends Node

var state = StateMachine.new()
var MAIN_MENU = state.add("main_menu")
var WITHIN_RUN = state.add("within_run")


var main_menu_scene = preload("res://main_menu.tscn")
var game_run_scene = preload("res://game_run.tscn")

func _ready():
	state.connect_signals(self)
	state.change_state(MAIN_MENU)

func clear_children():
	for node in get_children():
		node.queue_free()

func _on_main_menu_entered():
	var main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	main_menu.connect("new_game_selected", start_run)

func _on_main_menu_exited():
	clear_children()

func _on_within_run_entered():
	var game_run = game_run_scene.instantiate()
	game_run.connect("run_finished", finish_run)
	add_child(game_run)

func _on_within_run_exited():
	clear_children()

func start_run():
	state.change_state(WITHIN_RUN)

func finish_run():
	state.change_state(MAIN_MENU)
