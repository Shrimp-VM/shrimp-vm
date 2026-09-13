@tool
extends ShrimpIR
class_name ReadSymbolNode

@export var symbol: String

func execute(_vm: ShrimpVM, context: ExecutionContext) -> Variant:
	return context.env.read_symbol(symbol)
func decompile() -> Dictionary:
	return {
		"symbol": symbol
	}

static func create_from(wrapper: Dictionary) -> ReadSymbolNode:
	var result = new()
	result.symbol = wrapper.symbol
	return result
static func get_node_type() -> String:
	return "read_symbol"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Read symbol", {
		"symbol": Model.attribute_schema(
			TYPE_STRING,
			"symbol name"
		)
	}, "Read a symbol in the context.")
