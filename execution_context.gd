extends RefCounted
class_name ExecutionContext

signal exit(data: Variant)

enum LifeMode {
	STOP,
	PASS,
	IGNORE
}

var lifeMode: LifeMode
var parent: ExecutionContext
var env: ExecutionEnvironment
var running: bool = true

func _init(parenx: ExecutionContext = null, lifeModx: LifeMode = LifeMode.PASS, enx: ExecutionEnvironment = null) -> void:
	lifeMode = lifeModx
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
func exit_with(data: Variant):
	running = false
	exit.emit(data)
func stop_parent(data: Variant):
	if is_instance_valid(parent):
		if parent is ExecutionContext:
			parent.stop(data)
func stop(data: Variant):
	match lifeMode:
		LifeMode.STOP:
			exit_with(data)
		LifeMode.PASS:
			exit_with(data)
			stop_parent(data)
		LifeMode.IGNORE:
			stop_parent(data)
