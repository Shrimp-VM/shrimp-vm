@abstract
@tool
extends Resource
class_name ShrimpIR

const ERR_NOT_IMPLEMENTED = "Not Implemented"
const TYPE_ENUM = -1

@export var node_type: String

@abstract func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant

## 可以看成ts伪代码 {name:string,attributes:Record<string,{type:int,label:string,array:boolean}>}，type可以是字符串数组代表枚举，0代表任意类型
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return {
		"name": "Unnamed IR-Node",
		"attributes": {},
		"array": false
	}
static func get_node_type() -> String:
	assert(false, ERR_NOT_IMPLEMENTED)
	return "unknown_node"
static func create_from(wrapper: Dictionary, importer: ShrimpSyntaxTreeImporter, options: Dictionary) -> ShrimpIR:
	assert(false, ERR_NOT_IMPLEMENTED)
	return null
