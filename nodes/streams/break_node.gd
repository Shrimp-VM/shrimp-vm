@tool
extends ShrimpIR
class_name BreakNode

func execute(_vm: ShrimpVM, context: ShrimPoroutine) -> Variant:
	context.throw_break()
	return null
func decompile() -> Dictionary:
	return {}

static func get_category_tag() -> String:
	return "Streams"
static func get_node_type() -> String:
	return "break"
static func create_from(_wrapper: Dictionary) -> BreakNode:
	return new()
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Break", {}, "Stop the current loop.")
