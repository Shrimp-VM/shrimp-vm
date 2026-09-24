@tool
extends ShrimpIR
class_name YieldNode

@export var data: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	return context.pause_with(await vm.execute(data, context))
func decompile() -> Dictionary:
	return {
		"data": ShrimpCompiler.decompile(data)
	}

static func get_category_tag() -> String:
	return "Macro"
static func get_node_type() -> String:
	return "yield"
static func create_from(wrapper: Dictionary) -> YieldNode:
	var result = new()
	result.data = ShrimpCompiler.compile(wrapper.data)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Yield",
		{
			"data": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "data")
		},
		"Pause current running generator and yield a data."
	)
