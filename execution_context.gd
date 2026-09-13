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
var running: bool = false
var lastResult: Variant
var body: Array[ShrimpIR] = []
var statementIndex: int = 0

func _init(parenx: ExecutionContext = null, lifeModx: LifeMode = LifeMode.PASS, enx: ExecutionEnvironment = null) -> void:
	lifeMode = lifeModx
	if !is_instance_valid(enx):
		enx = ExecutionEnvironment.new()
	env = enx
	parent = parenx
	if is_instance_valid(parent):
		env.parent = parent.env

# Every context can only run 1 task the same time
func start(nodes: Array[ShrimpIR], vm: ShrimpVM):
	if running: return
	body = ShrimpVMUtil.erase_nonir(nodes)
	running = true
	statementIndex = 0
	lastResult = null
	while statementIndex < len(body):
		if !running: break
		var node = body[statementIndex]
		if is_instance_valid(node) && node is ShrimpIR:
			lastResult = await node.execute(vm, self)
		else:
			push_warning("%s is not a ShrimpIR, skipping execution." % node)
		statementIndex += 1
	return exit_with(lastResult)
func exit_with(data: Variant):
	running = false
	exit.emit(data)
	return data
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
