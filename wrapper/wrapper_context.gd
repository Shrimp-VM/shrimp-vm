extends RefCounted
class_name WrapperContext

var dataTree
var nodeTree: NodeBlock
var pointer: WrapperPath

func _init(data, pointex: WrapperPath = WrapperPath.from("/"), node: NodeBlock = null) -> void:
	dataTree = data
	pointer = pointex
	nodeTree = node

func get_pointer():
	return seek(pointer)
func run(path: WrapperPath) -> Variant:
	return seek(pointer.duplicate(true).concat(path).normalize())
func forward(path: WrapperPath) -> WrapperContext:
	return WrapperContext.new(dataTree, pointer.duplicate(true).concat(path).normalize(), nodeTree)
func seek(distPath: WrapperPath):
	var node = dataTree
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
				node = dataTree
		part = part.next
	return node
func locate(what: Array[GDScript] = [NodeBlock, NodeParameter]) -> Node:
	if !is_instance_valid(pointer): return null
	var result = nodeTree
	var pendingArray = []
	var pathPart = pointer.normalize().seek_root()
	while is_instance_valid(pathPart):
		match pathPart.type:
			WrapperPath.PartType.ATTRIBUTE:
				if result is NodeBlock:
					var param = result.parameterWrapper.get_node(pathPart.path) as NodeParameter
					if param.schema.array:
						pendingArray = param.arrayWrapper.get_children()
					else:
						var child = param.valueWrapper.get_child(0)
						if child.get_script() in what:
							result = child
						else:
							return result
				else:
					return result
			WrapperPath.PartType.INDEX:
				result = pendingArray.get(pathPart.path)
			WrapperPath.PartType.ROOT:
				result = nodeTree
		pathPart = pathPart.next
	return result
func is_root() -> bool:
	return pointer.is_root()
