extends Label

class_name SharedBagGoldUI

@export var shared_bag: SharedBag

func set_shared_bag(shared_bag: SharedBag):
	self.shared_bag = shared_bag
	set_gold(shared_bag.gold)
	shared_bag.gold_changed.connect(_on_gold_changed)

func _on_gold_changed(gold: int):
	set_gold(gold)

func set_gold(gold: int):
	set_text("%d🪙" % gold)
