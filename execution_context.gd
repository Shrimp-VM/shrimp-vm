extends RefCounted
class_name ExecutionContext

var parent: ExecutionContext
var env: ExecutionEnvironment
var running: bool = true

func _init(parenx: ExecutionContext = null, enx: ExecutionEnvironment = null) -> void:
	if !is_instance_valid(enx):
		enx = ExecutionEnvironment.new()
	env = enx
	parent = parenx
	if is_instance_valid(parent):
		env.parent = parent.env

func execute(node: ShrimpIR, vm: ShrimpVM):
	if !running: return
	if !is_instance_valid(node):
		push_warning("%s is not a ShrimpIR, skipping execution." % node)
		return null
	return await node.execute(vm, self)
func execute_body(body: Array[ShrimpIR], vm: ShrimpVM):
	for node in body:
		if !running: return
		await execute(node, vm)
	return
func stop():
	running = false
