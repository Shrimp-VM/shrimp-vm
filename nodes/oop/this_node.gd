@tool
extends ShrimpIR
class_name ThisNode

func execute(_vm: ShrimpVM, context: ExecutionContext) -> Variant:
	return context.env.read_symbol("this")
func decompile() -> Dictionary:
	return {}

static func get_category_tag() -> String:
	return "OOP"
static func get_node_type() -> String:
	return "this"
static func create_from(_wrapper: Dictionary) -> ThisNode:
	return new()
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("This", {}, "Get current instance in the context.")
