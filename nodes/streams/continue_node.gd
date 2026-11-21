@tool
extends ShrimpIR
class_name ContinueNode

func execute(_vm: ShrimpVM, context: ShrimPoroutine) -> Variant:
	context.throw_continue()
	return null
func decompile() -> Dictionary:
	return {}

static func get_category_tag() -> String:
	return "Streams"
static func get_node_type() -> String:
	return "continue"
static func create_from(_wrapper: Dictionary) -> ContinueNode:
	return new()
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Continue", {}, "Skip to the next loop iteration.")
