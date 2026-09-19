@tool
extends ShrimpIR
class_name ReturnNode

@export var data: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	return context.stop(await vm.execute(data, context), true)
func decompile() -> Dictionary:
	return {
		"data": ShrimpCompiler.decompile(data)
	}

static func get_category_tag() -> String:
	return "Macro"
static func get_node_type() -> String:
	return "return"
static func create_from(wrapper: Dictionary) -> ReturnNode:
	var result = new()
	result.data = ShrimpCompiler.compile(wrapper.data)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Return",
		{
			"data": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "data")
		},
		"Stop current running function and return a data."
	)
