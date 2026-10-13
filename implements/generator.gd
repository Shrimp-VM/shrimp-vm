@tool
extends RefCounted
class_name ShrimpGenerator

var coroutine: ShrimPoroutine
var vm: ShrimpVM

func _init(context: ShrimPoroutine, vmx: ShrimpVM) -> void:
	coroutine = context
	vm = vmx

func is_valid() -> bool:
	return is_instance_valid(coroutine) && coroutine.state != ShrimPoroutine.State.DONE
func next() -> Variant:
	if !is_valid():
		return null
	if coroutine.state == ShrimPoroutine.State.READY:
		drive_coroutine()
	else:
		coroutine.wake()
	if coroutine.state == ShrimPoroutine.State.SUSPENDED:
		return coroutine.lastResult
	if coroutine.state == ShrimPoroutine.State.RUNNING:
		coroutine.abort()
	return null
func drive_coroutine() -> void:
	await coroutine.drive_all()
