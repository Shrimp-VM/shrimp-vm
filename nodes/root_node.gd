@tool
extends ShrimpIR
class_name ShrimpRootNode

@export var body: Array[ShrimpIR] = []

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var newContext = ExecutionContext.new(context)
	vm.executeAll(body, newContext)
	return

static func get_node_type() -> String:
	return "root"
static func create_from(wrapper: Dictionary) -> ShrimpRootNode:
	var result = ShrimpRootNode.new()
	result.body = ShrimpSyntaxTreeImporter.create_ir_body(wrapper.body)
	return result
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return super.get_wrapper_schema().merged({
		"name": "Root Node",
		"attributes": {
			"body": {
				"type": ShrimpIR.TYPE_ENUM,
				"label": "Body",
				"array": true
			}
		}
	}, true)
