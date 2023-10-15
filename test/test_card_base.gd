extends GutTest

# Stage with starting_position next to single enemy skeleton warrior.
var test_stage_scene = preload("res://stages/test_card_base_1w.stage")

var stage: Stage
var map_manager: MapManager
var card_player: CardPlayer
var enemies: Node

var to_free: Array

func before_all():
	stage = test_stage_scene.instantiate() as Stage
	enemies = Node.new()
	stage.initialize(enemies)
	map_manager = MapManager.new()
	map_manager.initialize(stage, null)
	map_manager.set_enemies(enemies.get_children())
	var warrior = CharacterLoader.create(Enum.CharacterId.WARRIOR)
	warrior.set_id_position(stage.starting_positions[0])
	map_manager.set_party([warrior])
	map_manager = map_manager.clone(true)
	card_player = CardPlayer.new(map_manager, null)

	to_free = (
		[warrior, stage, enemies]
	)

func after_all():
	for node in to_free:
		node.free()
	card_player = null
	map_manager = null
	Node.print_orphan_nodes()

func create_damage_card(damage: int) -> Card:
	var card = Card.new()
	card.damage_value = CardEffectValue.new()
	card.damage_value.value_type = CardEffectValue.ValueType.ABSOLUTE
	card.damage_value.absolute_value = damage
	card.target_mode = Enum.TargetMode.ENEMY
	return card

func test_basic_attack():
	var card = create_damage_card(5)

	var warrior = map_manager.character_locs.values()[0]
	var enemy = map_manager.enemy_locs.values()[0]
	enemy.hit_points = 20
	var dir = (enemy.get_id_position() - warrior.get_id_position()) * 1.0
	card_player.play_card(autofree(UnitCard.new(warrior, card)), enemy.get_id_position(), dir * 1.0)

	assert_eq(enemy.hit_points, 15)

func test_basic_attack_kill():
	var card = create_damage_card(10)

	var warrior = map_manager.character_locs.values()[0]
	var enemy = map_manager.enemy_locs.values()[0]
	enemy.hit_points = 10
	var dir = (enemy.get_id_position() - warrior.get_id_position()) * 1.0
	card_player.play_card(autofree(UnitCard.new(warrior, card)), enemy.get_id_position(), dir * 1.0)

	assert_eq(enemy.is_destroyed, true)
