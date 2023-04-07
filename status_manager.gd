extends Resource

class_name StatusManager

@export var statuses = {}

func clear():
	statuses.clear()

func add_status(status: StatusDef.Status, value: int):
	if value == 0:
		return
	if status in statuses:
		statuses[status] += value
	else:
		statuses[status] = value

func decrement_status(status: StatusDef.Status, value: int = 1):
	if not status in statuses:
		return
	statuses[status] -= value
	if statuses[status] <= 0:
		statuses.erase(status)

func set_status(status: StatusDef.Status, value: int):
	statuses[status] = value

func clear_status(status: StatusDef.Status):
	if status in statuses:
		statuses.erase(status)

func get_status(status: StatusDef.Status) -> int:
	if status in statuses:
		return statuses[status]
	return 0

func clone() -> StatusManager:
	var copy = StatusManager.new()
	copy.statuses = statuses.duplicate()
	return copy
