@tool
extends ShrimpIR
class_name ShrimpRootNode

@export var body: Array[ShrimpIR] = []

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var newContext = ExecutionContext.new(context)
	await vm.execute_all(body, newContext)
	return
func decompile() -> Dictionary:
	return {
		"body": ShrimpCompiler.decompile_body(body)
	}

static func get_node_type() -> String:
	return "root"
static func create_from(wrapper: Dictionary) -> ShrimpRootNode:
	var result = ShrimpRootNode.new()
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"[color=#fffd99]Root Node[/color]",
		{
			"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
		},
		"Execute all codes in body."
	)
