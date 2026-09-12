@tool
extends ShrimpIR
class_name ShrimpFileChangeNameNode

@export var newName: String

func execute(_vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var filemgr = context.env.read_symbol("filemgr")
	if filemgr is ShrimpFileManager:
		if is_instance_valid(filemgr.currentOpening):
			filemgr.rename(newName)
			filemgr.rebuild()
	return
func decompile() -> Dictionary:
	return {
		"new_name": newName
	}

static func get_category_tag() -> String:
	return "Functions"
static func get_node_type() -> String:
	return "file_change_name"
static func create_from(wrapper: Dictionary) -> ShrimpFileChangeNameNode:
	var result = new()
	result.newName = wrapper.new_name
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema(
		"Rename the script",
		{
			"new_name": Model.attribute_schema(TYPE_STRING, "new name")
		},
		"Rename current script. Must in a filemgr context."
	)
