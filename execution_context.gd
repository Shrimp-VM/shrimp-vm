extends RefCounted
class_name ExecutionContext

enum LifeMode {
	STOP,
	PASS,
	IGNORE
}
enum State {
	READY,
	RUNNING,
	STOP
}

signal exited(data: Variant)

var lifeMode: LifeMode
var parent: ExecutionContext
var env: ExecutionEnvironment
var state: State = State.READY
var lastResult: Variant
var body: Array[ShrimpIR]
var vm: ShrimpVM
var currentNode: ShrimpIR
var currentIndex: int = 0
var tags: Dictionary = {}

func _init(parenx: ExecutionContext = null, lifeModx: LifeMode = LifeMode.PASS, enx: ExecutionEnvironment = null) -> void:
	lifeMode = lifeModx
	if !is_instance_valid(enx):
		enx = ExecutionEnvironment.new()
	env = enx
	parent = parenx
	if is_instance_valid(parent):
		env.reparent(parent.env)

func start(nodes: Array[ShrimpIR], vmx: ShrimpVM, startLoop: bool = true) -> Variant:
	if state != State.READY:
		return await ExecutionContext.new(self, lifeMode, env).start(nodes, vmx)
	body = ShrimpVMUtil.erase_nonir(nodes)
	vm = vmx
	state = State.RUNNING
	currentIndex = 0
	lastResult = null
	if startLoop:
		return await eventloop(vmx)
	else:
		return null
func eventloop(vmx: ShrimpVM = null) -> Variant:
	if is_instance_valid(vmx):
		vm = vmx
	elif !is_instance_valid(vm):
		assert(false, "Cannot run event loop without a VM.")
		return null
	while state == State.RUNNING && currentIndex < len(body):
		var node = body[currentIndex]
		var result = null
		if is_instance_valid(node) && node is ShrimpIR:
			currentNode = node
			result = await node.execute(vm, self)
		currentIndex += 1
		if state == State.RUNNING:
			lastResult = result
		else:
			return lastResult
	return exit_with(lastResult)
func is_exited() -> bool:
	return state == State.STOP || currentIndex >= len(body)
func exit_with(data: Variant):
	exited.emit(data)
	state = State.STOP
	currentIndex = len(body)
	lastResult = data
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
func has_parent(target: ExecutionContext) -> bool:
	if !is_instance_valid(target): return false
	if is_instance_valid(parent):
		if self == target:
			return true
		else:
			return parent.has_parent(target)
	else:
		return false
func reparent(new: ExecutionContext):
	if has_parent(new): return
	parent = new
	if is_instance_valid(parent):
		env.reparent(parent.env)
func reparent_head(new: ExecutionContext):
	if has_parent(new): return
	if is_instance_valid(parent):
		parent.reparent_head(new)
	else:
		reparent(new)
func merge(other: ExecutionContext):
	env.merge(other.env)
func merged(other: ExecutionContext) -> ExecutionContext:
	return ExecutionContext.new(parent, lifeMode, env.merged(other.env))
