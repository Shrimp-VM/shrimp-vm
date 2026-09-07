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
	return "File System"
static func get_node_type() -> String:
	return "file_change_name"
static func create_from(wrapper: Dictionary) -> ShrimpFileChangeNameNode:
	var result = new()
	result.newName = wrapper.new_name
	return result
static func get_wrapper_schema() -> Dictionary:
	return super.get_wrapper_schema().merged({
		"name": "Rename the script",
		"attributes": {
			"new_name": {
				"type": TYPE_STRING,
				"label": "new name"
			}
		}
	}, true)
