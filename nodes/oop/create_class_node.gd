@tool
extends ShrimpIR
class_name CreateClassNode

@export var name: String
@export var extend: ShrimpIR
@export var body: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var result = ShrimpClass.new(body, await vm.execute(extend, context), context)
	await result.init(vm)
	context.env.write_symbol(name, result)
	return result
func decompile() -> Dictionary:
	return {
		"name": name,
		"extends": ShrimpCompiler.decompile(extend),
		"body": ShrimpCompiler.decompile_body(body)
	}

static func get_category_tag() -> String:
	return "OOP"
static func get_node_type() -> String:
	return "create_class"
static func create_from(wrapper: Dictionary) -> CreateClassNode:
	var result = new()
	result.name = wrapper.name
	result.extend = ShrimpCompiler.compile(wrapper.extends )
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Create class", {
		"name": Model.attribute_schema(TYPE_STRING_NAME, "class name"),
		"extends": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "extends to"),
		"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "class body", true)
	}, "Create a named class with methods and attributes.")
