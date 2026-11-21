extends RefCounted
class_name ShrimPoroutine

enum State {
	READY,
	RUNNING,
	SUSPENDED,
	DONE
}

signal exited(data: Variant)
signal resumed()

var state: State = State.READY
var parent: ShrimPoroutine
var rootEnv: ExecutionEnvironment
var vm: ShrimpVM
var frames: Array[ShrimpFrame] = []
var pending: ShrimpControlSignal
var lastResult: Variant
var currentNode: ShrimpIR
var isGenerator: bool = false

var env: ExecutionEnvironment:
	get:
		if !frames.is_empty():
			return frames.back().env
		return rootEnv

func _init(parenx: ShrimPoroutine = null) -> void:
	parent = parenx
	if is_instance_valid(parenx):
		rootEnv = ExecutionEnvironment.new(parenx.env)
	else:
		rootEnv = ExecutionEnvironment.new()

func start(nodes: Array[ShrimpIR], vmx: ShrimpVM) -> Variant:
	if state == State.RUNNING:
		return await ShrimPoroutine.new(self).start(nodes, vmx)
	pending = null
	frames.clear()
	vm = vmx
	state = State.RUNNING
	frames.append(ShrimpFrame.new(ShrimpVMUtil.erase_nonir(nodes), rootEnv, ShrimpFrame.Boundary.BLOCK))
	await drive(0)
	finish(lastResult)
	return lastResult
func drive_all() -> Variant:
	state = State.RUNNING
	await drive(0)
	if state == State.RUNNING:
		finish(lastResult)
	return lastResult
func execute_block(nodes: Array[ShrimpIR], vmx: ShrimpVM, boundary: ShrimpFrame.Boundary = ShrimpFrame.Boundary.BLOCK, initSymbols: Dictionary = {}) -> Variant:
	vm = vmx
	var blockEnv = ExecutionEnvironment.new(env)
	for key in initSymbols:
		blockEnv.write_symbol(key, initSymbols[key])
	frames.append(ShrimpFrame.new(ShrimpVMUtil.erase_nonir(nodes), blockEnv, boundary))
	return await drive(frames.size() - 1)
func call_function(fn: ShrimpFunction, args: Array) -> Variant:
	if !is_instance_valid(vm):
		push_error("Cannot call function without a VM.")
		return null
	if len(args) > len(fn.params):
		push_error("Too much parameters")
		return null
	elif len(args) < len(fn.params):
		push_error("Too less parameters")
		return null
	if fn.generator:
		var genContext = ShrimPoroutine.new(fn.capturedContext)
		genContext.setup_function(fn, args, vm)
		return ShrimpGenerator.new(genContext, vm)
	setup_function(fn, args, vm)
	return await drive(frames.size() - 1)
func setup_function(fn: ShrimpFunction, args: Array, vmx: ShrimpVM) -> void:
	vm = vmx
	isGenerator = fn.generator
	var baseEnv = fn.capturedEnv if is_instance_valid(fn.capturedEnv) else rootEnv
	var frameEnv = ExecutionEnvironment.new(baseEnv)
	for i in len(fn.params):
		frameEnv.write_symbol(fn.params[i], args[i] if i < len(args) else null)
	frameEnv.write_symbol("this", fn.capturedThis)
	frames.append(ShrimpFrame.new(fn.body, frameEnv, ShrimpFrame.Boundary.FUNCTION, fn))
func suspend(value: Variant) -> Variant:
	lastResult = value
	state = State.SUSPENDED
	await resumed
	state = State.RUNNING
	return value
func wake() -> void:
	if state == State.SUSPENDED:
		resumed.emit()
func abort() -> void:
	finish(lastResult)
func interrupted() -> bool:
	return pending != null
func throw_return(value: Variant) -> void:
	pending = ShrimpControlSignal.new(ShrimpControlSignal.Type.RETURN, value)
func throw_break() -> void:
	pending = ShrimpControlSignal.new(ShrimpControlSignal.Type.BREAK)
func throw_continue() -> void:
	pending = ShrimpControlSignal.new(ShrimpControlSignal.Type.CONTINUE)
func throw_error(reason: Variant) -> void:
	pending = ShrimpControlSignal.new(ShrimpControlSignal.Type.ERROR, reason)
func reparent_head(new: ShrimPoroutine) -> void:
	if !is_instance_valid(new):
		return
	var head = rootEnv
	while is_instance_valid(head.parent) && head.parent != new.rootEnv:
		head = head.parent
	if head != new.rootEnv:
		head.parent = new.rootEnv
func merge(other: ShrimPoroutine) -> void:
	rootEnv.merge(other.rootEnv)
func drive(depth: int) -> Variant:
	while state == State.RUNNING:
		if pending != null:
			if frames.size() <= depth:
				break
			var captured = try_capture(depth)
			if captured != null:
				return captured
			continue
		if frames.size() <= depth:
			break
		var frame = frames.back()
		if frame.pointerIndex >= frame.body.size():
			frames.pop_back()
			continue
		var node = frame.body[frame.pointerIndex]
		frame.pointerIndex += 1
		if node is ShrimpIR:
			currentNode = node
			var result = await node.execute(vm, self)
			if state == State.RUNNING:
				lastResult = result
				frame.lastResult = result
	return null
func try_capture(depth: int) -> Variant:
	var frame = frames.back()
	var sig = pending
	match sig.type:
		ShrimpControlSignal.Type.RETURN:
			if frame.boundary == ShrimpFrame.Boundary.FUNCTION || depth == 0:
				pending = null
				frames.pop_back()
				lastResult = sig.value
				return sig.value
		ShrimpControlSignal.Type.BREAK, ShrimpControlSignal.Type.CONTINUE:
			if frame.boundary == ShrimpFrame.Boundary.LOOP:
				pending = null
				frames.pop_back()
				return sig
	frames.pop_back()
	return null
func finish(data: Variant) -> void:
	pending = null
	frames.clear()
	state = State.DONE
	lastResult = data
	exited.emit(data)
