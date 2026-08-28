@tool
extends Node
class_name ShrimpVM

@export_tool_button("Run") var run = executeRootNode
@export var rootNode: ShrimpIR

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if rootNode:
		executeRootNode()

func executeRootNode():
	execute(rootNode, ExecutionContext.new())
func execute(node: ShrimpIR, context: ExecutionContext) -> Variant:
	if !is_instance_valid(context):
		context = ExecutionContext.new()
	return node.execute.call(self, context)
func executeAll(nodes: Array[ShrimpIR], context: ExecutionContext) -> Variant:
	for node in nodes:
		execute(node, context)
	return
