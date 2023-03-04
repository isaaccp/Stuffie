extends RefCounted

class_name StageTriggerManager

var triggers: Array[StageTrigger]
var enemy_deaths = 0
var spawn_treasure_cb: Callable
var open_door_cb: Callable
var close_door_cb: Callable

func _init(triggers: Array[StageTrigger]):
	self.triggers = triggers

func connect_signals(gameplay: Gameplay):
	gameplay.enemy_died.connect(on_enemy_died)
	gameplay.new_turn_started.connect(on_begin_turn)
	spawn_treasure_cb = gameplay.spawn_treasure
	open_door_cb = gameplay.open_door
	close_door_cb = gameplay.close_door

func on_enemy_died():
	enemy_deaths += 1
	for trigger in triggers:
		if trigger.trigger_type == StageTrigger.TriggerType.ENEMIES_KILLED:
			if trigger.enemies_killed == enemy_deaths:
				call_callback(trigger)

func on_begin_turn(turn_number: int):
	for trigger in triggers:
		if trigger.trigger_type == StageTrigger.TriggerType.BEGIN_TURN:
			if trigger.turn == turn_number:
				call_callback(trigger)

func call_callback(trigger: StageTrigger):
	match trigger.effect_type:
		StageTrigger.EffectType.SPAWN_CHEST:
			spawn_treasure_cb.call()
		StageTrigger.EffectType.OPEN_DOOR:
			open_door_cb.call(trigger.door_pos)
		StageTrigger.EffectType.CLOSE_DOOR:
			close_door_cb.call(trigger.door_pos)
