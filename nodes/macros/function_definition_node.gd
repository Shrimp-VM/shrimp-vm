@tool
extends ShrimpIR
class_name FunctionDefinitionNode

class ContextGenerator:
	var context: ExecutionContext
	var vm: ShrimpVM

	func _init(contexx: ExecutionContext, vmx: ShrimpVM) -> void:
		context = contexx
		vm = vmx
	func is_valid() -> bool:
		return is_instance_valid(vm) && is_instance_valid(context) && !context.is_exited()
	func next() -> Variant:
		return await context.eventloop(vm)

@export var isAsync: bool
@export var isGenerator: bool
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
			var runContext = ExecutionContext.new(context, ExecutionContext.LifeMode.STOP)
			for i in len(params):
				runContext.env.write_symbol(params[i], input[i])
			if isGenerator:
				runContext.start(body, vm, false)
				return ContextGenerator.new(runContext, vm)
			else:
				return await vm.execute_all(body, runContext)
	context.env.write_symbol(functionName, data)
	return data
func decompile() -> Dictionary:
	return {
		"async": isAsync,
		"generator": isGenerator,
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
			"name": Model.attribute_schema(TYPE_STRING_NAME, "function name"),
			"params": Model.attribute_schema(TYPE_STRING_NAME, "parameters", true),
			"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
		},
		"Write a function symbol in current context."
	)
