@tool
extends ShrimpIR
class_name PlaceholderNode

func execute(_vm: ShrimpVM, _context: ExecutionContext) -> Variant:
	return
func decompile() -> Dictionary:
	return {}

static func is_hidden() -> bool:
	return true
static func get_node_type() -> String:
	return "placeholder"
static func create_from(_wrapper: Dictionary) -> PlaceholderNode:
	return new()
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("[color=red]PLACEHOLDER[/color]", {
		"param": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "Parameters", true)
	})
