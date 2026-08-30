@abstract
@tool
extends Resource
class_name ShrimpIR

const ERR_NOT_IMPLEMENTED = "Not Implemented"
const TYPE_ENUM = -1

@export var node_type: String

@abstract func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant
func decompile() -> Dictionary:
	return {}
func get_keys_type(attribute: String):
	return get_wrapper_schema().attributes[attribute].type

static func get_category_tag() -> String:
	return "基本"
static func get_node_type() -> String:
	assert(false, ERR_NOT_IMPLEMENTED)
	return "unknown_node"
## 可以看成ts伪代码 {name:string,attributes:Record<string,{type:int,label:string,array?:boolean,default?:any}>}，type可以是字符串数组代表枚举，0代表任意类型
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return {
		"name": "Unnamed IR-Node",
		"attributes": {}
	}
static func create_from(_wrapper: Dictionary) -> ShrimpIR:
	assert(false, ERR_NOT_IMPLEMENTED)
	return null
