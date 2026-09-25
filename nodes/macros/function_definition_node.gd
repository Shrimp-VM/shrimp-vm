@tool
extends ShrimpIR
class_name FunctionDefinitionNode

@export var isAsync: bool
@export var isGenerator: bool
@export var capture: bool
@export var functionName: String
@export var params: Array
@export var body: Array[ShrimpIR]

func execute(_vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var instance = ShrimpFunction.new(context, context.env.read_symbol("this") if capture else null, params, body, isAsync, isGenerator)
	context.env.write_symbol(functionName, instance)
	return instance
func decompile() -> Dictionary:
	return {
		"async": isAsync,
		"generator": isGenerator,
		"capture": capture,
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
	result.isAsync = wrapper.async
	result.isGenerator = wrapper.generator
	result.capture = wrapper.capture
	result.functionName = wrapper.name
	result.params = wrapper.params
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Define function",
		{
			"async": Model.attribute_schema(TYPE_BOOL, "is async?"),
			"generator": Model.attribute_schema(TYPE_BOOL, "is a generator?"),
			"capture": Model.attribute_schema(TYPE_BOOL, "capture this pointer?", false, true),
			"name": Model.attribute_schema(TYPE_STRING_NAME, "function name"),
			"params": Model.attribute_schema(TYPE_STRING_NAME, "parameters", true),
			"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
		},
		"Write a function symbol in current context."
	)
