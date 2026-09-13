@tool
extends Node
class_name ShrimpVM

@export_tool_button("Run") var run = execute_autorun
@export var auto_run: ShrimpIR

var poll_emitter: Signal

func _ready() -> void:
	if !Engine.is_editor_hint():
		if auto_run is ShrimpIR:
			execute_autorun()

func execute_autorun():
	await execute(auto_run, ExecutionContext.new())
func execute(node: ShrimpIR, context: ExecutionContext) -> Variant:
	return await execute_all([node], context)
func execute_all(nodes: Array[ShrimpIR], context: ExecutionContext) -> Variant:
	return await context.start(nodes, self)
func poll_event(scripts: Array[ShrimpIR], context: ExecutionContext):
	var irs = ShrimpVMUtil.get_configured_irs()
	for ir in irs:
		if ir.get_wrapper_schema().trigger != ShrimpIR.NodeTrigger.EVENT_POLL: return
		for headNode in scripts:
			if headNode.node_type != ir.get_node_type(): return
			var headTest = func():
				if await execute(headNode, context):
					await headNode.event_emit(self, context)
			headTest.call()
func trigger_event(node: String, scripts: Array[ShrimpIR], context: ExecutionContext, parameters: Dictionary = {}):
	var irs = ShrimpVMUtil.get_configured_irs()
	for ir in irs:
		var schema = ir.get_wrapper_schema()
		if schema.trigger != ShrimpIR.NodeTrigger.EVENT_TRIGGER: return
		if ir.get_node_type() != node: return
		for headNode in scripts:
			if headNode.node_type != ir.get_node_type(): return
			var headRun = func():
				var runContext = ExecutionContext.new(context)
				for attributeKey in schema.attributes:
					if schema.attributes[attributeKey].type == ShrimpIR.TYPE_EXTERNAL_PARAMETER:
						runContext.env.write_symbol("EVENT_%s" % attributeKey, parameters.get(attributeKey))
				await execute(headNode, runContext)
			headRun.call()
