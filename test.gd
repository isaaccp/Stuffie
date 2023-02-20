@tool
extends EditorScript

func _run():
	var foo = [1, 2, 3]
	print_debug(foo)
	foo = foo.slice(1)
	print_debug(foo)
