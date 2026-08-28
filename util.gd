class_name ShrimpVMUtil

static func hide_keys(dic: Dictionary, keys: Array[StringName]) -> Dictionary:
	var result = dic.duplicate()
	for key in keys:
		result.erase(key)
	return result
static func is_script_inherits(script: GDScript, ancestor: GDScript) -> bool:
	var current: Script = script
	while current != null:
		if current == ancestor:
			return true
		current = current.get_base_script()
	return false
static func disconnect_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
