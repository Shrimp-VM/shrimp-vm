@tool
extends ShrimpIR
class_name FunctionCallNode

@export var functionName: String
@export var paramIRs: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var data = context.env.read_symbol(functionName)
	if data is Callable:
		var input = []
		for ir in paramIRs:
			input.append(await vm.execute(ir, context))
		return await data.call(input)
	else:
		push_error("Function %s not found." % functionName)
		return null
func decompile() -> Dictionary:
	return {
		"name": functionName,
		"params": ShrimpCompiler.decompile_body(paramIRs)
	}

static func get_category_tag() -> String:
	return "Macro"
static func get_node_type() -> String:
	return "function_call"
static func create_from(wrapper: Dictionary) -> FunctionCallNode:
	var result = new()
	result.functionName = wrapper.name
	result.paramIRs = wrapper.params
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Call function",
		{
			"name": Model.attribute_schema(TYPE_STRING, "function name"),
			"params": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "parameters", true)
		},
		"Run a function symbol in current context."
	)
