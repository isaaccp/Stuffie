extends CanvasLayer

@export var color_rect: ColorRect
@export var animation_player: AnimationPlayer

signal blacked_out

func transition():
	animation_player.speed_scale = 2
	animation_player.play("fade_to_black")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_to_black":
		blacked_out.emit()
		animation_player.speed_scale = 1
		animation_player.play("fade_from_black")
	else:
		queue_free()
