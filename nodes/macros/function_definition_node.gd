@tool
extends ShrimpIR
class_name FunctionDefinitionNode

@export var functionName: String
@export var params: Array
@export var body: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var data = func(input: Array):
		if len(input) > len(params):
			push_error("Too much parameters")
		elif len(input) < len(params):
			push_error("Too less parameters")
		else:
			var callContext = ExecutionContext.new(context, ExecutionContext.LifeMode.STOP)
			for i in len(params):
				callContext.env.write_symbol(params[i], input[i])
			return await vm.execute_all(body, callContext)
	context.env.write_symbol(functionName, data)
	return data
func decompile() -> Dictionary:
	return {
		"name": functionName,
		"params": params,
		"body": ShrimpCompiler.decompile_body(body)
	}

static func get_category_tag() -> String:
	return "Macro"
static func get_node_type() -> String:
	return "function_definition"
static func create_from(wrapper: Dictionary) -> FunctionDefinitionNode:
	var result = new()
	result.functionName = wrapper.name
	result.params = wrapper.params
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Define function",
		{
			"name": Model.attribute_schema(TYPE_STRING_NAME, "function name"),
			"params": Model.attribute_schema(TYPE_STRING_NAME, "parameters", true),
			"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
		},
		"Write a function symbol in current context."
	)
