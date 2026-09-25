@tool
extends ShrimpIR
class_name FunctionCallNode

@export var function: ShrimpIR
@export var paramIRs: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var data = await vm.execute(function, context)
	if data is ShrimpFunction:
		return await data.run(await vm.execute_all(paramIRs, context), vm)
	else:
		push_error("Function %s not found." % function)
		return null
func decompile() -> Dictionary:
	return {
		"func": ShrimpCompiler.decompile(function),
		"params": ShrimpCompiler.decompile_body(paramIRs)
	}

static func get_category_tag() -> String:
	return "Macro"
static func get_node_type() -> String:
	return "function_call"
static func create_from(wrapper: Dictionary) -> FunctionCallNode:
	var result = new()
	result.function = ShrimpCompiler.compile(wrapper.func)
	result.paramIRs = ShrimpCompiler.compile_body(wrapper.params)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Call function",
		{
			"func": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "function object"),
			"params": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "parameters", true)
		},
		"Run a function in current context."
	)
