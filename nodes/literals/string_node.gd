@tool
extends ShrimpIR
class_name StringNode

@export var content: String

func execute(_vm: ShrimpVM, _context: ExecutionContext) -> Variant:
	return content

static func get_category_tag() -> String:
	return "Literals"
static func create_from(wrapper: Dictionary) -> StringNode:
	var result = new()
	result.content = wrapper.content
	return result
static func get_node_type() -> String:
	return "string_literal"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Any text", {
		"content": Model.attribute_schema(
			TYPE_STRING,
			"text"
		)
	}, "Just a literal")
