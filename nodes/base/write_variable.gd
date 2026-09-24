@tool
extends ShrimpIR
class_name WriteVariableNode

@export var symbol: String
@export var value: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	return context.env.write_symbol(symbol, await vm.execute(value, context))
func decompile() -> Dictionary:
	return {
		"symbol": symbol,
		"value": ShrimpCompiler.decompile(value)
	}

static func get_category_tag() -> String:
	return "Symbols"
static func create_from(wrapper: Dictionary) -> WriteVariableNode:
	var result = new()
	result.symbol = wrapper.symbol
	result.value = ShrimpCompiler.compile(wrapper.value)
	return result
static func get_node_type() -> String:
	return "write_variable"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Write variable", {
		"symbol": Model.attribute_schema(TYPE_STRING_NAME, "symbol name"),
		"value": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "variable value")
	}, "Write a variable in the context.")
