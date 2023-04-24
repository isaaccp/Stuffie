extends Node

class_name GameRun

var state = StateMachine.new()
var MAP = state.add("map")
var WITHIN_STAGE = state.add("within_stage")
var BETWEEN_STAGES = state.add("between_stages")
var RUN_SUMMARY = state.add("run_summary")

var stage_player_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")
var run_map_scene = preload("res://run_map.tscn")

var stage_name: String
var stage_impl: Node
var load_stage_from_save = false
var combat_state: CombatSaveState

var run_victory = false

var blacksmith_scene = preload("res://stages/blacksmith.tscn")
var camp_scene = preload("res://stages/camp.tscn")
var add_character_scene = preload("res://stages/add_character.tscn")
var event_scene = preload("res://stages/event.tscn")
var summary_scene = preload("res://run_summary.tscn")
var run: RunDef
var level_number = 0
var stage_number = 0
@export var shared_bag: SharedBag
const GOLD_PER_STAGE = 10

var characters: Array[Character]

@export var party: Node
@export var stage_parent: Node
@export var canvas: CanvasLayer
@export var menu: Control
@export var menu_screen_fader: ColorRect
@export var save_and_quit_button: Button
@export var abandon_button: Button

# Whether the last stage requires rewards.
var rewards_type = StageDef.RewardsType.NONE

var relic_list = preload("res://resources/relic_list.tres").duplicate()
var event_list = preload("res://resources/event_list.tres").duplicate()

var all_cards = Dictionary()
var run_type: RunDef.RunType
var added_levels = 0

signal run_finished

func _ready():
	state.connect_signals(self)
	relic_list.reset()
	event_list.reset()

func initialize_character(character: Character, full = true):
	character.shared_bag = shared_bag
	character.relic_manager.relic_list = relic_list
	character.set_canvas(canvas)
	if full:
		# Only for new stages, not when loading.
		var initial_relic = character.initial_relic
		relic_list.mark_used(initial_relic.name)
		character.add_relic(initial_relic, false)

		if run_type == RunDef.RunType.TEST_BLACKSMITH:
			character.deck.cards = character.all_cards.cards
		elif run_type == RunDef.RunType.TEST_CAMP:
			character.deck.cards = character.all_cards.cards
			character.hit_points -= 30
	characters.push_back(character)
	party.add_child(character)

func set_starting_characters(starting_characters: Array[Character]):
	# Improve this character initialization.
	for character in starting_characters:
		initialize_character(character)

func set_run_type(run_type: RunDef.RunType):
	self.run_type = run_type
	run = RunDef.get_run(run_type)
	shared_bag.add_gold(run.shared_bag_gold)

func start():
	state.change_state(MAP)

func current_stage_def():
	return run.get_stage(level_number, stage_number)

func load_stage(stage_name: String) -> Stage:
	var path = "res://stages/" + stage_name + ".stage"
	var scene = load(path) as PackedScene
	var stage = scene.instantiate() as Stage
	return stage

func get_combat_stage(difficulty: int):
	assert(difficulty < run.stages.size())
	var options = run.stages[difficulty]
	stage_name = options[randi() % options.size()]
	return load_stage(stage_name)

func get_blacksmith_stage():
	var stage = blacksmith_scene.instantiate() as BlacksmithStage
	return stage

func get_camp_stage():
	var stage = camp_scene.instantiate() as CampStage
	return stage

func get_card_reward_stage():
	var stage = between_stages_scene.instantiate()
	return stage

func get_character_stage():
	var stage = add_character_scene.instantiate()
	return stage

func get_event_stage():
	var stage = event_scene.instantiate() as EventStage
	return stage

func _on_within_stage_entered():
	var stage_def = current_stage_def()
	rewards_type = stage_def.rewards_type()
	if load_stage_from_save:
		var stage_player = stage_player_scene.instantiate()
		var stage = load_stage(stage_name)
		stage_parent.add_child(stage_player)
		stage_player.initialize(stage, party, shared_bag, combat_state)
		stage_player.stage_done.connect(stage_finished.bind(StageDef.StageType.COMBAT))
		stage_player.game_over.connect(game_over)
		stage_impl = stage_player
	else:
		StatsManager.add_level(Enum.StatsLevel.STAGE)
		if stage_def.stage_type == StageDef.StageType.COMBAT:
			var stage_player = stage_player_scene.instantiate()
			var stage = get_combat_stage(stage_def.combat_difficulty)
			for enemy in stage.enemies:
				enemy.level += run.added_levels + stage_def.combat_added_levels
			stage_parent.add_child(stage_player)
			stage_player.initialize(stage, party, shared_bag)
			stage_player.stage_done.connect(stage_finished.bind(StageDef.StageType.COMBAT))
			stage_player.game_over.connect(game_over)
			stage_impl = stage_player
		elif stage_def.stage_type == StageDef.StageType.BLACKSMITH:
			var blacksmith = get_blacksmith_stage()
			blacksmith.initialize(characters, shared_bag, relic_list, stage_def.blacksmith_removals, stage_def.blacksmith_upgrades, stage_def.blacksmith_relics)
			blacksmith.stage_done.connect(stage_finished.bind(StageDef.StageType.BLACKSMITH))
			stage_parent.add_child(blacksmith)
			stage_impl = blacksmith
		elif stage_def.stage_type == StageDef.StageType.CAMP:
			var camp = get_camp_stage()
			camp.initialize(characters, shared_bag)
			camp.stage_done.connect(stage_finished.bind(StageDef.StageType.CAMP))
			stage_parent.add_child(camp)
			stage_impl = camp
		elif stage_def.stage_type == StageDef.StageType.CARD_REWARD:
			var card_reward = get_card_reward_stage()
			card_reward.initialize(characters, shared_bag, stage_def.card_reward_options)
			card_reward.between_stages_done.connect(stage_finished.bind(StageDef.StageType.CARD_REWARD))
			stage_parent.add_child(card_reward)
			stage_impl = card_reward
		elif stage_def.stage_type == StageDef.StageType.CHARACTER:
			var character_stage = get_character_stage()
			character_stage.initialize(characters)
			character_stage.character_selected().connect(character_added)
			stage_parent.add_child(character_stage)
			stage_impl = character_stage
		elif stage_def.stage_type == StageDef.StageType.EVENT:
			var event_stage = get_event_stage()
			var event = event_list.choose()
			assert(event != null)
			event_stage.initialize(event, characters, shared_bag, relic_list)
			event_stage.stage_done.connect(stage_finished.bind(StageDef.StageType.EVENT))
			stage_parent.add_child(event_stage)
			stage_impl = event_stage

func _on_within_stage_exited():
	await TransitionScreen.create(self)
	# If we had restore state from a save, drop it as we have
	# now finished the stage.
	load_stage_from_save = false
	combat_state = null
	for node in stage_parent.get_children():
		node.queue_free()
	if current_stage_def().stage_type == StageDef.StageType.COMBAT:
		for character in characters:
			character.end_stage()
	stage_number += 1
	if stage_number == run.get_level(level_number).stages.size():
		stage_number = 0
		level_number += 1

func _on_between_stages_entered():
	# Possibly just push this into between_stages and
	# handle it there. Or rename "between_stages" to "rewards_stage".
	if rewards_type == StageDef.RewardsType.NONE:
		state.change_state.call_deferred(MAP)
	else:
		shared_bag.add_gold(GOLD_PER_STAGE)
		for character in characters:
			StatsManager.add(character.character_type, Stats.Field.GOLD_EARNED, GOLD_PER_STAGE/characters.size())
		var between_stages = between_stages_scene.instantiate()
		between_stages.initialize(characters, shared_bag)
		stage_parent.add_child(between_stages)
		between_stages.between_stages_done.connect(state.change_state.bind(MAP))

func _on_between_stages_exited():
	for node in stage_parent.get_children():
		node.queue_free()

func _on_map_entered():
	var run_map = run_map_scene.instantiate() as RunMap
	run_map.initialize(run, level_number, stage_number, shared_bag)
	stage_parent.add_child(run_map)
	run_map.done.connect(next_stage)

func _on_map_exited():
	await TransitionScreen.create(self)
	for node in stage_parent.get_children():
		node.queue_free()

func _on_run_summary_entered():
	var summary = summary_scene.instantiate() as RunSummary
	summary.initialize(characters, run_victory)
	stage_parent.add_child(summary)
	summary.done.connect(finish_run)

func _on_run_summary_exited():
	pass

func add_stat(field: Stats.Field, value: int):
	for character in characters:
		StatsManager.add(character.character_type, field, value)

func character_added(character: Character):
	initialize_character(character)
	stage_finished(StageDef.StageType.CHARACTER)

func stage_finished(stage_type: StageDef.StageType):
	StatsManager.remove_level(Enum.StatsLevel.STAGE)
	if stage_type == StageDef.StageType.COMBAT:
		add_stat(Stats.Field.COMBAT_STAGES_FINISHED, 1)
	StatsManager.run_stats.print()
	if stage_number + 1 == run.get_level(level_number).stages.size():
		if level_number + 1 == run.levels.size():
			add_stat(Stats.Field.RUNS_VICTORY, 1)
			run_victory = true
			state.change_state(RUN_SUMMARY)
		else:
			state.change_state(BETWEEN_STAGES)
	else:
		state.change_state(BETWEEN_STAGES)

func next_stage():
	state.change_state(WITHIN_STAGE)

func game_over():
	if not state.is_state(MAP):
		StatsManager.remove_level(Enum.StatsLevel.STAGE)
	add_stat(Stats.Field.RUNS_DEFEAT, 1)
	state.change_state(RUN_SUMMARY)

func finish_run():
	run_finished.emit()

func show_menu():
	menu.show()
	var stage = stage_parent.get_child(0)
	save_and_quit_button.disabled = (stage and not stage.can_save())
	get_tree().paused = true
	var tw = create_tween()
	tw.tween_property(menu_screen_fader, "color", Color(0, 0, 0, 0.75), 0.25)

func hide_menu():
	menu.hide()
	get_tree().paused = false
	var tw = create_tween()
	tw.tween_property(menu_screen_fader, "color", Color(0, 0, 0, 0), 0.25)

func _input(event):
	if Input.is_action_just_released("ui_cancel"):
		if state.is_state(RUN_SUMMARY):
			return
		if menu.visible:
			hide_menu()
		else:
			show_menu()

func _on_abandon_run_pressed():
	var stage = stage_parent.get_child(0)
	if stage:
		stage.cleanup()
	menu.hide()
	get_tree().paused = false
	game_over()

func _on_save_quit_pressed():
	var main_game = $/root/MainGame
	main_game.save_game_state()
	get_tree().paused = false
	get_tree().quit()

func get_save_state():
	var run_state = RunSaveState.new()
	run_state.run_type = run_type
	run_state.state = state.current_state_name()
	run_state.stage_number = stage_number
	run_state.gold = shared_bag.gold
	run_state.relic_list = relic_list
	run_state.event_list = event_list
	for character in characters:
		run_state.characters.push_back(character.get_save_state())
	if state.is_state(MAP):
		# If we are on map, this is the easiest situation. Just
		# need to restore to map, nothing extra to save.
		pass
	else:
		run_state.stage_type = current_stage_def().stage_type
		match run_state.stage_type:
			StageDef.StageType.COMBAT:
				run_state.stage_name = stage_name
				run_state.combat_state = stage_impl.get_save_state()
			StageDef.StageType.BLACKSMITH:
				pass
			StageDef.StageType.CAMP:
				pass
			StageDef.StageType.CARD_REWARD:
				pass
	return run_state

func load_save_state(run_state: RunSaveState):
	set_run_type(run_state.run_type)
	stage_number = run_state.stage_number
	shared_bag.gold = run_state.gold
	relic_list = run_state.relic_list
	event_list = run_state.event_list
	for character_data in run_state.characters:
		var character = CharacterLoader.restore(character_data)
		initialize_character(character, false)
	match run_state.state:
		MAP.name:
			state.change_state(MAP)
		WITHIN_STAGE.name:
			match run_state.stage_type:
				StageDef.StageType.COMBAT:
					load_stage_from_save = true
					stage_name = run_state.stage_name
					combat_state = run_state.combat_state
					state.change_state(WITHIN_STAGE)
