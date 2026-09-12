@tool
extends ShrimpIR
class_name BooleanNode

@export var content: bool

func execute(_vm: ShrimpVM, _context: ExecutionContext) -> Variant:
	return content
func decompile() -> Dictionary:
	return {
		"content": content
	}

static func get_category_tag() -> String:
	return "Literals"
static func create_from(wrapper: Dictionary) -> BooleanNode:
	var result = new()
	result.content = wrapper.content
	return result
static func get_node_type() -> String:
	return "boolean_literal"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Any boolean", {
		"content": Model.attribute_schema(
			TYPE_BOOL,
			"state"
		)
	}, "Just a literal")
