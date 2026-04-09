extends Node3D

class_name CameraController

var camera_panning_speed = 15
var camera_rotation_speed = 100

signal camera_moved

@onready var camera: Camera3D = $Camera3D

func _process(delta):
	var camera_move = delta * camera_panning_speed
	var camera_rotate = delta * camera_rotation_speed
	var camera_forward = -transform.basis.z
	camera_forward.y = 0
	var forward = camera_forward.normalized() * camera_move
	var camera_modified = false
	
	if Input.is_action_pressed("ui_right"):
		position += forward.cross(Vector3.UP)
		camera_modified = true
	if Input.is_action_pressed("ui_left"):
		position -= forward.cross(Vector3.UP)
		camera_modified = true
	if Input.is_action_pressed("ui_up"):
		position += forward
		camera_modified = true
	if Input.is_action_pressed("ui_down"):
		position -= forward
		camera_modified = true
	if Input.is_action_pressed("ui_rotate_left"):
		rotate_y(-camera_rotate*delta)
		camera_modified = true
	if Input.is_action_pressed("ui_rotate_right"):
		rotate_y(camera_rotate*delta)
		camera_modified = true
	if Input.is_action_just_released("ui_zoom_in"):
		camera.fov -= 1
		if camera.fov < 10:
			camera.fov = 10
	if Input.is_action_just_released("ui_zoom_out"):
		camera.fov += 1
		if camera.fov > 100:
			camera.fov = 100
			
	if camera_modified:
		camera_moved.emit()
