@tool
extends ShrimpIR
class_name ShrimpAddNode

@export var left: ShrimpIR
@export var right: ShrimpIR

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var l = await vm.execute(left, context)
	var r = await vm.execute(right, context)
	return l + r
func decompile() -> Dictionary:
	return {
		"left": ShrimpCompiler.decompile(left),
		"right": ShrimpCompiler.decompile(right)
	}

static func get_category_tag() -> String:
	return "Mathmatics"
static func get_node_type() -> String:
	return "add"
static func create_from(wrapper: Dictionary) -> ShrimpAddNode:
	var result = new()
	result.left = ShrimpCompiler.compile(wrapper.left)
	result.right = ShrimpCompiler.compile(wrapper.right)
	return result
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return super.get_wrapper_schema().merged({
		"name": "Add Numbers",
		"attributes": {
			"left": {
				"type": ShrimpIR.TYPE_ENUM,
				"label": "left number"
			},
			"right": {
				"type": ShrimpIR.TYPE_ENUM,
				"label": "right number"
			}
		}
	}, true)
