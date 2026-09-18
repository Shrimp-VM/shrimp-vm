extends RefCounted
class_name WrapperContext

var tree
var pointer: WrapperPath

func get_pointer():
	return seek(pointer)
func run(path: WrapperPath) -> Variant:
	return seek(pointer.duplicate(true).concat(path).normalize())
func forward(path: WrapperPath) -> WrapperContext:
	var next := WrapperContext.new()
	next.tree = tree
	next.pointer = pointer.duplicate(true).concat(path).normalize()
	return next
func seek(distPath: WrapperPath):
	var node = tree
	var part: WrapperPath = distPath.seek_root()
	while is_instance_valid(part):
		match part.type:
			WrapperPath.PartType.ATTRIBUTE:
				if node is Dictionary:
					node = node.get(part.path)
				else:
					push_error("Must execute attribute on a Dictionary.")
					return null
			WrapperPath.PartType.INDEX:
				if node is Array:
					var i: int = part.path
					if i >= 0 && i < node.size():
						node = node[i]
					else:
						push_error("Index out of range: %d" % i)
						return null
				else:
					push_error("Must execute index on an Array.")
					return null
			WrapperPath.PartType.ROOT:
				node = tree
		part = part.next
	return node
func is_root() -> bool:
	return pointer.is_root()
