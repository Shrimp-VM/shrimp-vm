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
func has_parent(target: ExecutionEnvironment) -> bool:
	if is_instance_valid(parent):
		if self == target:
			return true
		else:
			return parent.has_parent(target)
	else:
		return false
func reparent(new: ExecutionEnvironment):
	if has_parent(new): return
	parent = new
func merge(other: ExecutionEnvironment):
	symbols.merge(other.symbols, true)
func merged(other: ExecutionEnvironment) -> ExecutionEnvironment:
	var result = ExecutionEnvironment.new(parent)
	result.symbols = symbols.merged(other.symbols, true)
	return result
