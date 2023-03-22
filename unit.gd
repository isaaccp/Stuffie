extends WorldEntity

class_name Unit

@export var total_move_points: int
var move_points: int
var power: int
var weakness: int
var paralysis: int

func add_power(power_amount: int):
	self.power += power_amount
	add_stat(Stats.Field.POWER_ACQUIRED, power_amount)
	changed.emit()

func begin_turn():
	super()

func end_turn():
	super()
	move_points = total_move_points
	if power > 0:
		power -= 1
	if weakness > 0:
		weakness -= 1
	if paralysis > 0:
		paralysis -= 1
