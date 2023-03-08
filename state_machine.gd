extends Object

class_name StateMachine

class State:
	var name: String
	var id: int

	func _init(name: String, id: int):
		self.name = name
		self.id = id

	func enter_signal():
		return "%s_entered" % name

	func exit_signal():
		return "%s_existed" % name

	func enter_method():
		return "_on_%s_entered" % name

	func exit_method():
		return "_on_%s_exited" % name

var id: int
var state: State
var states: Array[State]
var obj: Object

func _init():
	self.id = Time.get_ticks_usec()
	state = null

func add(name: String):
	var state = State.new(name, id)
	states.push_back(state)
	return state

func is_state(state: State):
	assert(state.id == id)
	return self.state == state

func change_state(new_state: State):
	assert(new_state.id == id)
	if state != null:
		if state.name == new_state.name:
			return
		await obj.call(state.exit_method())
	state = new_state
	await obj.call(state.enter_method())

func connect_signals(obj: Object):
	self.obj = obj
	for s in states:
		assert(obj.has_method(s.enter_method()))
		assert(obj.has_method(s.exit_method()))
