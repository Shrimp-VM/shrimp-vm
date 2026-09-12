@tool
extends ShrimpIR
class_name PrintNode

@export var content: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	print(await vm.execute(content, context))
	return

static func get_category_tag() -> String:
	return "Functions"
static func create_from(wrapper: Dictionary) -> PrintNode:
	var result = new()
	result.content = ShrimpCompiler.compile(wrapper.content)
	return result
static func get_node_type() -> String:
	return "print"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Print something to console", {
		"content": Model.attribute_schema(
			ShrimpIR.TYPE_ENUM,
			"Content"
		)
	}, "Hello World!!!")
