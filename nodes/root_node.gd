@tool
extends ShrimpIR
class_name ShrimpRootNode

@export var body: Array[ShrimpIR] = []

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var newContext = ExecutionContext.new(context)
	for node in body:
		vm.execute(node, newContext)
	return

static func get_node_type() -> String:
	return "root"
static func create_from(wrapper: Dictionary, importer: ShrimpSyntaxTreeImporter, options: Dictionary) -> ShrimpRootNode:
	var result = ShrimpRootNode.new()
	result.body = [] as Array[ShrimpIR]
	for node in wrapper.body:
		result.body.append(importer.create_ir(node, options))
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
