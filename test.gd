@tool
extends EditorScript

func test():
	pass

func _run():
	var thread = Thread.new()
	thread.start(test)
	OS.delay_msec(100)
	print_debug(thread.get_id())
	print_debug("is_alive: ", thread.is_alive())
	thread.wait_to_finish()
	print_debug(thread.get_id())
	print_debug("is_alive: ", thread.is_alive())
