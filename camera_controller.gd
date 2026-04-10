extends Node3D

class_name CameraController

var camera_panning_speed = 15
var camera_rotation_speed = 100
var tile_size: int = 2

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

func snap_to_direction(vector: Vector2) -> Vector2:
	var min_distance = null
	var direction = null
	for v in [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT]:
		var distance = vector.distance_squared_to(v)
		if min_distance == null:
			min_distance = distance
			direction = v
		else:
			if distance < min_distance:
				min_distance = distance
				direction = v
	return direction

func mouse_pos_to_plane_pos(mouse_pos: Vector2) -> Vector3:
	var camera_from = camera.project_ray_origin(mouse_pos)
	var camera_to = camera.project_ray_normal(mouse_pos)
	var n = Vector3(0, 1, 0) # plane normal
	var p = camera_from
	var v = camera_to
	# distance from plane
	var d = -2
	var t = - (n.dot(p) + d) / n.dot(v)
	return p + t * v

func plane_pos_to_tile_pos(plane_pos: Vector3) -> Vector2i:
	return Vector2i(floor(plane_pos.x / tile_size), floor(plane_pos.z / tile_size))

func add_unprojected_point(line: Line2D, world_pos: Vector3):
	var unprojected = camera.unproject_position(world_pos)
	line.add_point(unprojected)

