extends Control

class_name RunMap

signal done

var finished = false
var run: Array
var stage_number: int

@export var panel: Panel
@export var combat: Texture
@export var blacksmith: Texture
@export var boss: Texture
@export var path: Texture
@export var camp: Texture
@export var card_reward: Texture
@export var shared_bag_gold_ui: SharedBagGoldUI

var between_stage_space: float
var vertical_center: float

func initialize(run: Array, stage_number: int, shared_bag: SharedBag):
	self.run = run
	self.stage_number = stage_number
	shared_bag_gold_ui.set_shared_bag(shared_bag)

func _ready():
	between_stage_space = size.x / (run.size() + 1)
	vertical_center = size.y / 2
	var i = 0
	for stage in run:
		var item = prepare_item(i)
		if i > stage_number:
			item.modulate = Color(1, 1, 1, 0.5)
		panel.add_child(item)
		if (i + 1) == run.size():
			continue
		var path = make_path(i)
		if i >= stage_number:
			path.modulate = Color(1, 1, 1, 0.5)
		panel.add_child(path)
		i += 1

func get_sprite(texture: Texture, index: int, rotation_degrees=0, offset=Vector2.ZERO) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(1.5, 1.5)
	sprite.rotation_degrees = rotation_degrees
	var pos = Vector2(between_stage_space * (index+1), vertical_center)
	sprite.set_position(pos + offset)
	return sprite

func prepare_item(index: int) -> Sprite2D:
	match run[index].stage_type:
			GameRun.StageType.COMBAT:
				if index != run.size() -1:
					return get_sprite(combat, index)
				else:
					return get_sprite(boss, index)
			GameRun.StageType.BLACKSMITH:
				return get_sprite(blacksmith, index)
			GameRun.StageType.CAMP:
				return get_sprite(camp, index)
			GameRun.StageType.CARD_REWARD:
				return get_sprite(card_reward, index)
	assert(false)
	return null

func make_path(index: int) -> Sprite2D:
	return get_sprite(path, index, 90, Vector2(between_stage_space/2, 0))

func _input(event):
	if finished:
		return

	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			finished = true
			done.emit()

func can_save():
	return true

# Invoked when abandoning run while this stage is on.
func cleanup():
	pass
