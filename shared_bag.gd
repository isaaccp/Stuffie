extends Node

class_name SharedBag

var gold = 0

signal gold_changed(gold: int)

func add_gold(gold: int):
	self.gold += gold
	gold_changed.emit(self.gold)

func spend_gold(gold: int):
	assert(gold <= self.gold)
	self.gold -= gold
	gold_changed.emit(self.gold)
