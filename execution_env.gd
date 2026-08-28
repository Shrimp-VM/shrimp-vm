extends RefCounted
class_name ExecutionEnvironment

var symbols: Dictionary[StringName, Variant] = {}
var parent: ExecutionEnvironment = null

func _init(parenx: ExecutionEnvironment = null) -> void:
	parent = parenx

func readSymbol(key: StringName) -> Variant:
	if symbols.has(key):
		return symbols[key]
	elif is_instance_valid(parent):
		return parent.readSymbol(key)
	else:
		return null
func writeSymbol(key: StringName, value: Variant):
	symbols.set(key, value)
