@tool
extends RefCounted
class_name ShrimpInstance

var prototype: ShrimpClass = null
var instanceContext: ExecutionContext

func read_attribute(key: StringName) -> Variant:
	return instanceContext.env.read_symbol(key)
func write_attribute(key: StringName, value: Variant):
	instanceContext.env.write_symbol(key, value)
func call_super_method(name: StringName, vm: ShrimpVM = null, args: Array = []):
	var method = read_attribute("$%s" % name)
	if method is ShrimpFunction:
		await method.run(args, vm)
