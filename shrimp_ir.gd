@abstract
@tool
extends Resource
class_name ShrimpIR

class Model:
	static func wrapper_schema(name: String, attributes: Dictionary):
		return {
			"name": name,
			"attributes": attributes
		}
	static func attribute_schema(type: Variant, label: String, array: bool = false, default: Variant = null):
		return {
			"type": type,
			"label": label,
			"array": array
		}.merged({"default": default} if default != null else {})

const ERR_NOT_IMPLEMENTED = "Not Implemented"
const TYPE_ENUM = -1

@export var node_type: String

@abstract func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant
func decompile() -> Dictionary:
	return {}
func get_keys_type(attribute: String):
	return get_wrapper_schema().attributes[attribute].type

static func get_category_tag() -> String:
	return "Base Nodes"
static func get_node_type() -> String:
	assert(false, ERR_NOT_IMPLEMENTED)
	return "unknown_node"
## Fake type script:
## interface Wrapper {
##     name: string;
## 	   attributes: Record<
## 	      string,
## 		  {
## 		      type: int | string[],
## 			  label: string,
## 			  array?: boolean=false,
## 			  default?: any=null
## 		  }
## 	  >;
## }
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return {
		"name": "Unnamed IR-Node",
		"attributes": {}
	}
static func create_from(_wrapper: Dictionary) -> ShrimpIR:
	assert(false, ERR_NOT_IMPLEMENTED)
	return null
