@tool
extends ShrimpIR
class_name WhileNode

@export var condition: ShrimpIR
@export var body: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	while !(await vm.execute(condition, context)):
		await vm.execute_body(body, context)
	return
func decompile() -> Dictionary:
	return {
		"condition": ShrimpCompiler.decompile(condition),
		"body": ShrimpCompiler.decompile_body(body),
	}

static func get_node_type() -> String:
	return "while"
static func get_category_tag() -> String:
	return "Streams"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Repeat ... until ...", {
		"condition": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "condition"),
		"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
	})
static func create_from(wrapper: Dictionary) -> WhileNode:
	var result = new()
	result.condition = ShrimpCompiler.compile(wrapper.condition)
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
