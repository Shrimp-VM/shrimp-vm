extends RefCounted
class_name ExecutionEnvironment

var symbols: Dictionary[StringName, Variant] = {}
var parent: ExecutionEnvironment = null

func _init(parenx: ExecutionEnvironment = null) -> void:
	parent = parenx

func read_symbol(key: StringName) -> Variant:
	if symbols.has(key):
		return symbols[key]
	elif is_instance_valid(parent):
		return parent.read_symbol(key)
	else:
		return null
func write_symbol(key: StringName, value: Variant):
	symbols.set(key, value)
func delete_symbol(key: StringName):
	symbols.erase(key)
