extends Control

class_name BlacksmithStage

var done = false
var running = false

signal stage_done

func _process(_delta):
	if not running:
		running = true
		if not done:
			await get_tree().create_timer(1.0).timeout
			stage_done.emit()
