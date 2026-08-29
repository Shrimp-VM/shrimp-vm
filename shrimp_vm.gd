@tool
extends Node
class_name ShrimpVM

@export_tool_button("Run") var run = execute_root_node
@export var root_node: ShrimpIR

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if root_node:
		execute_root_node()

func execute_root_node():
	execute(root_node, ExecutionContext.new())
func execute(node: ShrimpIR, context: ExecutionContext) -> Variant:
	if !is_instance_valid(node):
		push_warning("%s is not a IR-Node, execution skipping." % node)
		return null
	if !is_instance_valid(context):
		context = ExecutionContext.new()
	return node.execute.call(self, context)
func execute_all(nodes: Array[ShrimpIR], context: ExecutionContext) -> Variant:
	for node in nodes:
		execute(node, context)
	return
