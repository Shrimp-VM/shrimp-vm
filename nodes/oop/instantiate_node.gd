@tool
extends ShrimpIR
class_name InstantiateNode

@export var classInstance: ShrimpIR
@export var initArgs: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant:
	var classI = await vm.execute(classInstance, context)
	if classI is ShrimpClass:
		return await classI.create_instantiate(await vm.execute_all(initArgs, context), vm)
	else:
		return null
func decompile() -> Dictionary:
	return {
		"class": ShrimpCompiler.decompile(classInstance),
		"args": ShrimpCompiler.decompile_body(initArgs)
	}

static func get_category_tag() -> String:
	return "OOP"
static func get_node_type() -> String:
	return "instantiate"
static func create_from(wrapper: Dictionary) -> InstantiateNode:
	var result = new()
	result.classInstance = ShrimpCompiler.compile(wrapper.class )
	result.initArgs = ShrimpCompiler.compile_body(wrapper.args)
	return result
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Instantaite class", {
		"class": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "class instance"),
		"args": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "init args", true)
	}, "Instantiate a class with init arguments.")
