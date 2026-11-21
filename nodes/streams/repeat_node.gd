@tool
extends ShrimpIR
class_name RepeatNode

@export var times: ShrimpIR
@export var symbol: String
@export var body: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ShrimPoroutine) -> Variant:
	for i in floor(await vm.execute(times, context)):
		if context.interrupted():
			break
		var sig = await context.execute_block(body, vm, ShrimpFrame.Boundary.LOOP, {symbol: i})
		if sig is ShrimpControlSignal && sig.type == ShrimpControlSignal.Type.BREAK:
			break
	return
func decompile() -> Dictionary:
	return {
		"times": ShrimpCompiler.decompile(times),
		"symbol": symbol,
		"body": ShrimpCompiler.decompile_body(body),
	}

static func get_node_type() -> String:
	return "repeat_times"
static func get_category_tag() -> String:
	return "Streams"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Repeat N times", {
		"times": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "times"),
		"symbol": Model.attribute_schema(TYPE_STRING_NAME, "iterator symbol"),
		"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
	})
static func create_from(wrapper: Dictionary) -> RepeatNode:
	var result = new()
	result.times = ShrimpCompiler.compile(wrapper.times)
	result.symbol = wrapper.symbol
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
