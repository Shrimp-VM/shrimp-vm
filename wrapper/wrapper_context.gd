extends RefCounted
class_name WrapperContext

var tree: Dictionary
var pointer: WrapperPath

func get_target():
	return pointer.execute_root(tree)
