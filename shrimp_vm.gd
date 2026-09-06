@tool
extends Node
class_name ShrimpVM

@export_tool_button("Run") var run = execute_autorun
@export var auto_run: ShrimpIR
@export var scripts: Array[ShrimpIR]

var poll_emitter: Signal

func _ready() -> void:
	if !Engine.is_editor_hint():
		if auto_run is ShrimpIR:
			execute_autorun()

func execute_autorun():
	await execute(auto_run, ExecutionContext.new())
func execute(node: ShrimpIR, context: ExecutionContext) -> Variant:
	return await context.execute(node, self)
func execute_all(nodes: Array[ShrimpIR], context: ExecutionContext) -> Variant:
	return await context.execute_body(nodes, self)
func poll_event():
	var irs = ShrimpVMUtil.get_ir_nodes()
	for ir in irs:
		if ir.get_wrapper_schema().trigger != ShrimpIR.NodeTrigger.EVENT_POLL: return
		for script in scripts:
			if script.node_type != ir.get_node_type(): return
			#
func emit_polling(emitter: Signal):
	if is_instance_valid(poll_emitter):
		poll_emitter.disconnect(poll_event)
	emitter.connect(poll_event)
	poll_emitter = emitter
