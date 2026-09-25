@tool
extends ShrimpIR
class_name MemberAccessNode

@export var object: ShrimpIR
@export var key: String
@export var write: bool
@export var value: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var obj = await vm.execute(object, context)
	if write:
		var v = await vm.execute(value, context)
		if obj is ShrimpInstance:
			obj.write_attribute(key, v)
		elif obj is Object:
			obj.set(key, v)
		return v
	else:
		if obj is ShrimpInstance:
			return obj.read_attribute(key)
		elif obj is Object:
			return obj.get(key)
		else:
			return null
func decompile() -> Dictionary:
	return {
		"object": ShrimpCompiler.decompile(object),
		"key": key,
		"write": write,
		"value": ShrimpCompiler.decompile(value)
	}

static func get_category_tag() -> String:
	return "OOP"
static func get_node_type() -> String:
	return "member_access"
static func create_from(wrapper: Dictionary) -> MemberAccessNode:
	var result = new()
	result.object = ShrimpCompiler.compile(wrapper.object)
	result.key = wrapper.key
	result.write = wrapper.write
	result.value = ShrimpCompiler.compile(wrapper.value)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Member access", {
		"object": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "object"),
		"key": Model.attribute_schema(TYPE_STRING_NAME, "key"),
		"write": Model.attribute_schema(TYPE_BOOL, "write"),
		"value": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "value")
	}, "Access a attribute of an object.")
