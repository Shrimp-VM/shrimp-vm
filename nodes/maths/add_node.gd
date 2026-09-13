@tool
extends ShrimpIR
class_name AddNode

@export var a: ShrimpIR
@export var b: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	return (await vm.execute(a, context)) + (await vm.execute(b, context))
func decompile() -> Dictionary:
	return {
		"a": ShrimpCompiler.decompile(a),
		"b": ShrimpCompiler.decompile(b)
	}

static func get_category_tag() -> String:
	return "Mathmatics"
static func get_node_type() -> String:
	return "add"
static func create_from(wrapper: Dictionary) -> AddNode:
	var result = new()
	result.a = wrapper.a
	result.b = wrapper.b
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Add", {
		"a": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "A"),
		"b": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "B"),
	}, "Add two numbers.")
