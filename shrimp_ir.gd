@abstract
@tool
extends Resource
class_name ShrimpIR

class Model:
	static func wrapper_schema(name: String, attributes: Dictionary, trigger: NodeTrigger = NodeTrigger.EXECUTION):
		return {
			"name": name,
			"attributes": attributes,
			"trigger": trigger
		}
	static func attribute_schema(type: Variant, label: String, array: bool = false, default: Variant = null):
		return {
			"type": type,
			"label": label,
			"array": array
		}.merged({"default": default} if default != null else {})

const ERR_NOT_IMPLEMENTED = "Not Implemented"
const TYPE_ENUM = -1
const TYPE_EXTERNAL_PARAMETER = -2

enum NodeTrigger {
	EXECUTION,
	EVENT_POLL,
	EVENT_TRIGGER,
	TERMINAL
}

@export var node_type: String

## EXECUTION=Orderly run, EVENT=event test, returns a bool, TERMINAL=stop, can't connect next sibling
@abstract func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant
func event_emit(_vm: ShrimpVM, _context: ExecutionContext):
	pass
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
##    trigger: NodeTrigger;
## }
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return Model.wrapper_schema("Unnamed ShrimpIR", {})
static func create_from(_wrapper: Dictionary) -> ShrimpIR:
	assert(false, ERR_NOT_IMPLEMENTED)
	return null
