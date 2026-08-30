@tool
extends ShrimpIR
class_name TestNode

func execute(_vm: ShrimpVM, _context: ExecutionContext) -> Variant:
	return

static func get_node_type() -> String:
	return "test"
static func create_from(_wrapper: Dictionary) -> TestNode:
	return new()
static func get_wrapper_schema() -> Dictionary[String, Variant]:
	return super.get_wrapper_schema().merged({
		"name": "Test Node",
		"attributes": {
			"attr1": {
				"type": TYPE_STRING,
				"label": "attr1"
			},
			"attr2": {
				"type": TYPE_FLOAT,
				"label": "attr2"
			},
			"attr3": {
				"type": ShrimpIR.TYPE_ENUM,
				"label": "attr3"
			},
			"attr4": {
				"type": ["A", "B", "C"],
				"label": "attr4"
			},
			"attr5": {
				"type": TYPE_BOOL,
				"label": "attr5"
			}
		}
	}, true)
