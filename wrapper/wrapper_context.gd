extends RefCounted
class_name WrapperContext

var tree
var pointer: WrapperPath

func get_target():
	return pointer.execute_root(tree)
func run(path: WrapperPath) -> Variant:
	var distPath = pointer.duplicate(true).concat(path).normalize()
	match distPath.type:
		WrapperPath.PartType.ATTRIBUTE:
			if tree is Dictionary:
				return tree.get(path)
			else:
				push_error("Mush execute attribute on a Wrapper.")
		WrapperPath.PartType.INDEX:
			if tree is Array:
				return tree.get(path)
			else:
				push_error("Mush execute index on a Array.")
	push_error("Unmatched part type.")
	return null
func forward(path: WrapperPath):
	tree = run(path)
	return tree
