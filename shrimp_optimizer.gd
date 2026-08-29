@tool
extends RefCounted
class_name ShrimpOptimizer

signal warning(type: WarnType, message: String)

enum WarnType {
	NULL_NODE,
	NULL_ROOT
}

var input: ShrimpIR
var result: ShrimpIR

func _init(inpux: ShrimpIR) -> void:
	input = inpux

func warn(type: WarnType, message: String = ""):
	warning.emit(type, message)
func optimize() -> ShrimpIR:
	result = input
	if result == null:
		warn(WarnType.NULL_ROOT)
		return result
	execute(result, result.get_node_type())
	return result
func execute(node: ShrimpIR, path: String) -> void:
	for prop in node.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var value = node.get(prop.name)
		match prop.type:
			TYPE_OBJECT:
				if value == null:
					warn(WarnType.NULL_NODE, "%s.%s" % [path, prop.name])
				elif value is ShrimpIR:
					execute(value, "%s.%s" % [path, prop.name])
			TYPE_ARRAY:
				if value is Array:
					for i in value.size():
						var item = value[i]
						if item == null:
							warn(WarnType.NULL_NODE, "%s.%s[%d]" % [path, prop.name, i])
						elif item is ShrimpIR:
							execute(item, "%s.%s[%d]" % [path, prop.name, i])
