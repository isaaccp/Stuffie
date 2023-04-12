extends Resource

class_name EventList

@export var events: Array[EventDef]

@export var remaining_events: Array[EventDef]

func reset():
	remaining_events = events.duplicate()
	remaining_events.shuffle()

func choose() -> EventDef:
	return remaining_events.pop_back()
