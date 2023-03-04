extends Node3D

class_name Door

enum DoorState {
	NO_STATE,
	OPEN,
	CLOSED,
}

@export var animation_player: AnimationPlayer

var state: DoorState

func _ready():
	if state == DoorState.OPEN:
		animation_player.play("Open Door")
		animation_player.advance(animation_player.current_animation_length)

func open():
	if state == DoorState.OPEN:
		return
	animation_player.play("Open Door")
	state = DoorState.OPEN

func close():
	if state != DoorState.OPEN:
		return
	animation_player.play_backwards("Open Door")
	state = DoorState.CLOSED

func solid() -> bool:
	return state != DoorState.OPEN
