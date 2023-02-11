extends Control

var load_time: int
var done = false

signal between_stages_done

func _ready():
	load_time = Time.get_ticks_msec()
	
func _process(delta):
	if not done:
		if Time.get_ticks_msec() - load_time > 1000:
			between_stages_done.emit()
			done = true
