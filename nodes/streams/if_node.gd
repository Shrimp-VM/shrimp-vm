@tool
extends ShrimpIR
class_name IfNode

@export var condition: ShrimpIR
@export var thenBody: Array[ShrimpIR]
@export var elseBody: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var result = await vm.execute(condition, context)
	if result:
		await vm.execute_body(thenBody, context)
	else:
		await vm.execute_body(elseBody, context)
	return result
func decompile() -> Dictionary:
	return {
		"condition": ShrimpCompiler.decompile(condition),
		"thenBody": ShrimpCompiler.decompile_body(thenBody),
		"elseBody": ShrimpCompiler.decompile_body(elseBody)
	}

static func get_node_type() -> String:
	return "if"
static func get_category_tag() -> String:
	return "Streams"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("If ... then ...", {
		"condition": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "condition"),
		"thenBody": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "condition met", true),
		"elseBody": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "condition not met", true)
	})
static func create_from(wrapper: Dictionary) -> IfNode:
	var result = new()
	result.condition = ShrimpCompiler.compile(wrapper.condition)
	result.thenBody = ShrimpCompiler.compile_body(wrapper.thenBody)
	result.elseBody = ShrimpCompiler.compile_body(wrapper.elseBody)
	return result
