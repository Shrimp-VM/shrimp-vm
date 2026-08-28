@abstract
@tool
extends Resource
class_name ShrimpIR

const ERR_NOT_IMPLEMENTED = "Not Implemented"

@export var node_type: String

@abstract func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant

static func get_node_type() -> String:
	assert(false, ERR_NOT_IMPLEMENTED)
	return "unknown_node"
static func create_from(wrapper: Dictionary, importer: ShrimpSyntaxTreeImporter, options: Dictionary) -> ShrimpIR:
	assert(false, ERR_NOT_IMPLEMENTED)
	return null
