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
var body: Array[ShrimpIR]
var currentNode: ShrimpIR
var currentIndex: int = 0

func _init(parenx: ExecutionContext = null, lifeModx: LifeMode = LifeMode.PASS, enx: ExecutionEnvironment = null) -> void:
	lifeMode = lifeModx
	if !is_instance_valid(enx):
		enx = ExecutionEnvironment.new()
	env = enx
	parent = parenx
	if is_instance_valid(parent):
		env.reparent(parent.env)

# Every context can only run 1 task the same time
func start(nodes: Array[ShrimpIR], vm: ShrimpVM) -> Variant:
	if running:
		return await ExecutionContext.new(parent, lifeMode, env).start(nodes, vm)
	body = ShrimpVMUtil.erase_nonir(nodes)
	running = true
	currentIndex = 0
	lastResult = null
	while currentIndex < len(body):
		if !running:
			return lastResult
		var node = body[currentIndex]
		if is_instance_valid(node) && node is ShrimpIR:
			currentNode = node
			var result = await node.execute(vm, self)
			if running:
				lastResult = result
		else:
			push_warning("%s is not a ShrimpIR, skipping execution." % node)
		currentIndex += 1
	return exit_with(lastResult)
func exit_with(data: Variant):
	lastResult = data
	exit.emit(data)
	running = false
	return data
func stop_parent(data: Variant, spread: bool = false):
	if is_instance_valid(parent):
		if parent is ExecutionContext:
			parent.stop(data, spread)
func stop(data: Variant, spread: bool = false):
	match lifeMode:
		LifeMode.STOP:
			exit_with(data)
		LifeMode.PASS:
			exit_with(data)
			if spread: stop_parent(data, spread)
		LifeMode.IGNORE:
			if spread: stop_parent(data, spread)
	return data
