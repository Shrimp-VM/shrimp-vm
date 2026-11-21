@tool
extends ShrimpIR
class_name ForNode

@export var iterator: ShrimpIR
@export var symbol: String
@export var body: Array[ShrimpIR]

func execute(vm: ShrimpVM, context: ShrimPoroutine) -> Variant:
	var iteratox = await vm.execute(iterator, context)
	if iteratox is ShrimpGenerator:
		while iteratox.is_valid() && !context.interrupted():
			var value = await iteratox.next()
			if !iteratox.is_valid():
				break
			var sig = await context.execute_block(body, vm, ShrimpFrame.Boundary.LOOP, {symbol: value})
			if sig is ShrimpControlSignal && sig.type == ShrimpControlSignal.Type.BREAK:
				break
	else:
		for i in iteratox:
			if context.interrupted():
				break
			var sig = await context.execute_block(body, vm, ShrimpFrame.Boundary.LOOP, {symbol: i})
			if sig is ShrimpControlSignal && sig.type == ShrimpControlSignal.Type.BREAK:
				break
	return
func decompile() -> Dictionary:
	return {
		"iterator": ShrimpCompiler.decompile(iterator),
		"symbol": symbol,
		"body": ShrimpCompiler.decompile_body(body),
	}

static func get_node_type() -> String:
	return "for"
static func get_category_tag() -> String:
	return "Streams"
static func get_wrapper_schema() -> Dictionary:
	return Model.wrapper_schema("Iter each items in ...", {
		"iterator": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "iterator"),
		"symbol": Model.attribute_schema(TYPE_STRING_NAME, "item symbol"),
		"body": Model.attribute_schema(ShrimpIR.TYPE_ENUM, "body", true)
	})
static func create_from(wrapper: Dictionary) -> ForNode:
	var result = new()
	result.iterator = ShrimpCompiler.compile(wrapper.iterator)
	result.symbol = wrapper.symbol
	result.body = ShrimpCompiler.compile_body(wrapper.body)
	return result
