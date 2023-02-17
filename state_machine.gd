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


func _init():
	self.id = Time.get_ticks_usec()
	self.states = states
	state = null

func add(name: String):
	var state = State.new(name, id)
	states.push_back(state)
	add_user_signal(state.enter_signal())
	add_user_signal(state.exit_signal())
	return state
	
func change_state(new_state: State):
	assert(new_state.id == id)
	if state != null:
		if state.name == new_state.name:
			return
		emit_signal(state.exit_signal())
	state = new_state
	emit_signal(new_state.enter_signal())

func connect_signals(obj: Object):
	for s in states:
		assert(obj.has_method(s.enter_method()))
		assert(obj.has_method(s.exit_method()))
		connect(s.enter_signal(), Callable(obj, s.enter_method()))
		connect(s.exit_signal(), Callable(obj, s.exit_method()))
